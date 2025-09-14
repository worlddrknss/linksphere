terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

locals {
  project = var.project_name
}

// VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${local.project}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${local.project}-igw" }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  map_public_ip_on_launch = true
  availability_zone = element(data.aws_availability_zones.available.names, index(keys(toset(var.public_subnets)), each.key))
  tags = {
    Name = "${local.project}-public-${each.key}"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${local.project}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

// Security group for ALB and ECS
resource "aws_security_group" "alb_sg" {
  name   = "${local.project}-alb-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${local.project}-ecs-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ALB
resource "aws_lb" "alb" {
  name               = "${local.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]
}

resource "aws_lb_target_group" "frontend_tg" {
  name     = "${local.project}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

// ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${local.project}-cluster"
}

// IAM roles
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.project}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// Task definitions (Fargate)
resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.project}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      portMappings = [
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.project}-backend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.project}-backend"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.project}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      portMappings = [
        { containerPort = 80, hostPort = 80, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.project}-frontend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.project}-frontend"
  retention_in_days = 7
}

// Fargate services
resource "aws_ecs_service" "backend" {
  name            = "${local.project}-backend-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.desired_count_backend
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [for s in aws_subnet.public : s.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "frontend" {
  name            = "${local.project}-frontend-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.desired_count_frontend
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [for s in aws_subnet.public : s.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}
