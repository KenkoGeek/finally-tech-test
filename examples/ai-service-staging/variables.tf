# AWS Configuration
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ai-service"
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
  default     = "staging"
}

# Container Image Configuration
variable "image_registry" {
  description = "Container image registry"
  type        = string
  default     = "public.ecr.aws/mycompany"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

# ECS Configuration
variable "ecs_cluster_id" {
  description = "ECS cluster ID/ARN"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "1024"
}

variable "task_memory" {
  description = "Memory for the task"
  type        = string
  default     = "2048"
}

variable "desired_count" {
  description = "Desired number of tasks to run"
  type        = number
  default     = 2
}

variable "launch_type" {
  description = "ECS launch type"
  type        = string
  default     = "FARGATE"
}

variable "force_new_deployment" {
  description = "Force new deployment"
  type        = bool
  default     = false
}

# Container Configuration
variable "api_cpu" {
  description = "CPU units for API container"
  type        = number
  default     = 512
}

variable "api_memory" {
  description = "Memory for API container"
  type        = number
  default     = 1024
}

variable "api_port" {
  description = "Port for API container"
  type        = number
  default     = 8080
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

# Load Balancer Configuration
variable "alb_arn" {
  description = "ALB ARN"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN"
  type        = string
}

variable "alb_listener_rules" {
  description = "ALB listener rules configuration"
  type = map(map(object({
    priority = number
    conditions = list(object({
      type   = string
      values = list(string)
      key    = optional(string)
    }))
  })))
  default = {
    "ai-api" = {
      "api-rule" = {
        priority = 100
        conditions = [
          {
            type   = "path_pattern"
            values = ["/api/*"]
          }
        ]
      }
    }
  }
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

# Auto Scaling Configuration
variable "min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = number
  default     = 10
}

variable "cpu_threshold_high" {
  description = "CPU threshold for scaling up"
  type        = number
  default     = 80
}

variable "cpu_threshold_low" {
  description = "CPU threshold for scaling down"
  type        = number
  default     = 20
}

variable "cpu_evaluation_period" {
  description = "CPU evaluation period"
  type        = number
  default     = 2
}

variable "cpu_period" {
  description = "CPU period"
  type        = number
  default     = 300
}

variable "cooldown_period" {
  description = "Cooldown period for scaling"
  type        = number
  default     = 300
}

# Logging Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "ai-service"
  }
}

variable "container_environment_variables" {
  description = "Map of environment variables for the container"
  type        = map(string)
  default = {
    "NODE_ENV" = "staging"
    "LOG_LEVEL" = "debug"
  }
}