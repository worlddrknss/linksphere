output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "frontend_service" {
  value = aws_ecs_service.frontend.name
}

output "backend_service" {
  value = aws_ecs_service.backend.name
}
