variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "linksphere"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "backend_image" {
  description = "Full image URI for backend (including tag), e.g. registry.gitlab.com/org/project/linksphere-backend:TAG"
  type        = string
}

variable "frontend_image" {
  description = "Full image URI for frontend (including tag), e.g. registry.gitlab.com/org/project/linksphere-frontend:TAG"
  type        = string
}

variable "desired_count_backend" {
  type    = number
  default = 2
}

variable "desired_count_frontend" {
  type    = number
  default = 2
}
