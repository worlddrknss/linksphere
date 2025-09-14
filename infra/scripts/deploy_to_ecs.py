#!/usr/bin/env python3
"""
deploy_to_ecs.py

Assumes GitLab CI has already built and pushed Docker images to the GitLab Container Registry.
This script updates ECS task definitions / services so they point to the new images.

Usage (example):
  export GITLAB_REGISTRY=registry.gitlab.com/myorg/linksphere
  export AWS_PROFILE=default
  python3 infra/scripts/deploy_to_ecs.py \
    --backend-image-tag v1.2.3 --frontend-image-tag v1.2.3 \
    --ecs-cluster linksphere-cluster --ecs-service backend-service \
    --frontend-ecs-service frontend-service

Requires:
  - boto3 (pip install boto3)
  - AWS credentials configured (env or profile)
"""
import argparse
import os
import sys

import boto3


def aws_update_service_image(region, cluster, service, container_name, new_image):
    client = boto3.client('ecs', region_name=region)
    # fetch current task definition for the service
    svc_resp = client.describe_services(cluster=cluster, services=[service])
    services = svc_resp.get('services', [])
    if not services:
        raise RuntimeError(f"Service {service} not found in cluster {cluster}")
    svc = services[0]
    td_arn = svc['taskDefinition']
    td = client.describe_task_definition(taskDefinition=td_arn)['taskDefinition']

    # Create a new container definitions list with updated image for the target container
    new_defs = []
    found = False
    for c in td['containerDefinitions']:
        # copy the container definition to avoid mutating original
        cnew = dict(c)
        if cnew['name'] == container_name:
            cnew['image'] = new_image
            found = True
        new_defs.append(cnew)

    if not found:
        raise RuntimeError(f"Container named {container_name} not found in task definition {td['taskDefinitionArn']}")

    register_kwargs = {
        'family': td['family'],
        'taskRoleArn': td.get('taskRoleArn'),
        'executionRoleArn': td.get('executionRoleArn'),
        'networkMode': td.get('networkMode'),
        'containerDefinitions': new_defs,
        'volumes': td.get('volumes', []),
        'placementConstraints': td.get('placementConstraints', []),
        'requiresCompatibilities': td.get('requiresCompatibilities', []),
        'cpu': td.get('cpu'),
        'memory': td.get('memory'),
    }

    # Remove None values
    register_kwargs = {k: v for k, v in register_kwargs.items() if v is not None}

    print('Registering new task definition revision...')
    resp = client.register_task_definition(**register_kwargs)
    new_td_arn = resp['taskDefinition']['taskDefinitionArn']
    print('New task definition:', new_td_arn)

    print('Updating service to use new task definition...')
    client.update_service(cluster=cluster, service=service, taskDefinition=new_td_arn, forceNewDeployment=True)
    print('Service update requested; waiting for stable status...')
    waiter = client.get_waiter('services_stable')
    waiter.wait(cluster=cluster, services=[service])
    print('Service is stable')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--backend-image-tag', required=True)
    parser.add_argument('--frontend-image-tag', required=True)
    parser.add_argument('--gitlab-registry', default=os.getenv('GITLAB_REGISTRY'))
    parser.add_argument('--aws-region', default=os.getenv('AWS_REGION', 'us-east-1'))
    parser.add_argument('--ecs-cluster', required=True)
    parser.add_argument('--ecs-service', required=True, help='ECS service name to update for backend')
    parser.add_argument('--frontend-ecs-service', required=False, help='Optional ECS service name to update for frontend')
    parser.add_argument('--backend-container-name', default='backend')
    parser.add_argument('--frontend-container-name', default='frontend')
    args = parser.parse_args()

    if not args.gitlab_registry:
        print('GITLAB_REGISTRY must be set via env or --gitlab-registry')
        sys.exit(1)

    registry = args.gitlab_registry.rstrip('/')

    backend_image = f"{registry}/linksphere-backend:{args.backend_image_tag}"
    frontend_image = f"{registry}/linksphere-frontend:{args.frontend_image_tag}"

    # Update backend service
    print('Updating ECS service to use new backend image...')
    aws_update_service_image(region=args.aws_region, cluster=args.ecs_cluster, service=args.ecs_service, container_name=args.backend_container_name, new_image=backend_image)

    # Optionally update frontend service if provided
    if args.frontend_ecs_service:
        print('Updating ECS service to use new frontend image...')
        aws_update_service_image(region=args.aws_region, cluster=args.ecs_cluster, service=args.frontend_ecs_service, container_name=args.frontend_container_name, new_image=frontend_image)

    print('Deployment to ECS complete')


if __name__ == '__main__':
    main()
