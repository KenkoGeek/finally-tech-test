terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# AI Service ECS Module - Production Configuration
module "ai_service" {
  source = "git::https://github.com/KenkoGeek/finally-tech-test.git?ref=v1.0.0"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # ECS Configuration - Production sizing
  ecs_cluster_id = var.ecs_cluster_id
  task_family    = "${var.project_name}-${var.environment}"
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory
  desired_count  = var.desired_count

  # Container Configuration - Production optimized
  container_name     = "ai-api"
  container_image    = "${var.image_registry}/${var.project_name}:${var.image_tag}"
  container_cpu      = var.api_cpu
  container_memory   = var.api_memory
  container_port     = var.api_port
  host_port          = var.api_port
  container_essential = true

  # Network Configuration - Multi-AZ
  vpc_id           = var.vpc_id
  subnets          = var.subnet_ids
  alb_listener_rules          = var.alb_listener_rules
  assign_public_ip = var.assign_public_ip

  # Load Balancer Configuration
  alb_listener_arn   = var.alb_listener_arn
  health_check_path  = var.health_check_path

  # Auto Scaling Configuration - Production settings
  scale_target_min_capacity = var.min_capacity
  scale_target_max_capacity = var.max_capacity
  max_cpu_threshold         = var.cpu_threshold_high
  min_cpu_threshold         = var.cpu_threshold_low
  max_cpu_evaluation_period = var.cpu_evaluation_period
  min_cpu_evaluation_period = var.cpu_evaluation_period
  max_cpu_period            = var.cpu_period
  min_cpu_period            = var.cpu_period
  cooldown                  = var.cooldown_period

  # Logging Configuration - Extended retention
  log_retention_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  # Launch Configuration
  launch_type           = var.launch_type
  force_new_deployment  = var.force_new_deployment

  # Tags
  tags = var.tags
  #checkov:skip=CKV_TF_1: "Hash commit not needed"
}