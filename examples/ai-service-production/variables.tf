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
  description = "Environment name (production)"
  type        = string
  default     = "production"
}

# ECS Configuration
variable "ecs_cluster_id" {
  description = "ECS cluster ID/ARN"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task (production sizing)"
  type        = string
  default     = "2048"
}

variable "task_memory" {
  description = "Memory for the task (production sizing)"
  type        = string
  default     = "4096"
}

variable "desired_count" {
  description = "Desired number of tasks to run (production)"
  type        = number
  default     = 5
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
variable "image_registry" {
  description = "Docker image registry URL"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag (production version)"
  type        = string
}

# API Container - Production sizing
variable "api_cpu" {
  description = "CPU units for API container (production)"
  type        = number
  default     = 1536
}

variable "api_memory" {
  description = "Memory for API container (production)"
  type        = number
  default     = 3072
}

variable "api_port" {
  description = "Port for API container"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path for API"
  type        = string
  default     = "/health"
}

# Redis Container - Production sizing
variable "redis_image" {
  description = "Redis Docker image"
  type        = string
  default     = "redis:7-alpine"
}

variable "redis_cpu" {
  description = "CPU units for Redis container (production)"
  type        = number
  default     = 512
}

variable "redis_memory" {
  description = "Memory for Redis container (production)"
  type        = number
  default     = 1024
}

variable "redis_port" {
  description = "Port for Redis container"
  type        = number
  default     = 6379
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (production - multiple AZs)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "alb_arn" {
  description = "Application Load Balancer ARN"
  type        = string
}

variable "alb_listener_arn" {
  description = "Application Load Balancer listener ARN"
  type        = string
}

variable "alb_listener_rules" {
  description = "ALB listener rules configuration for production"
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
      },
      "health-rule" = {
        priority = 200
        conditions = [
          {
            type   = "path_pattern"
            values = ["/health"]
          }
        ]
      }
    }
  }
}

variable "health_check_path" {
  description = "Health check path for ALB target groups"
  type        = string
  default     = "/health"
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

# Auto Scaling Configuration - Production settings
variable "min_capacity" {
  description = "Minimum number of tasks (production)"
  type        = number
  default     = 5
}

variable "max_capacity" {
  description = "Maximum number of tasks (production)"
  type        = number
  default     = 20
}

variable "cpu_threshold_high" {
  description = "CPU threshold for scaling up (production)"
  type        = string
  default     = "80"
}

variable "cpu_threshold_low" {
  description = "CPU threshold for scaling down (production)"
  type        = string
  default     = "30"
}

variable "cpu_evaluation_period" {
  description = "Number of periods for CPU evaluation"
  type        = number
  default     = 3
}

variable "cpu_period" {
  description = "Period in seconds for CPU metrics"
  type        = number
  default     = 300
}

variable "cooldown_period" {
  description = "Cooldown period in seconds (production)"
  type        = number
  default     = 600
}

# Application Configuration
variable "log_level" {
  description = "Application log level (production)"
  type        = string
  default     = "WARN"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "api_key_secret_arn" {
  description = "ARN of the secret containing API keys"
  type        = string
}

# Logging Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention in days (production)"
  type        = number
  default     = 90
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
}

# Service Connect
variable "enable_service_connect" {
  description = "Enable ECS Service Connect"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "ai-platform"
    ManagedBy   = "terraform"
  }
}