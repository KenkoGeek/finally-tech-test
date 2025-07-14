variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "my-workload"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Invalid project name. Please provide a valid name using lowercase letters and hyphens (-)."
  }
}

variable "aws_region" {
  description = "The AWS region to deploy the resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Deployment Environment"
  default     = "development"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Invalid environment name. Please provide a valid name using lowercase letters and hyphens (-)."
  }
}
# Security Group
variable "security_group_rules_cidrs" {
  description = "Map of security group rules with CIDR block, port, and description"
  type = map(object({
    cidr        = string
    from_port   = number
    to_port     = number
    description = string
    protocol    = string
  }))
  default = {
    ssh = {
      cidr        = "10.0.0.0/24"
      from_port   = 22
      to_port     = 22
      description = "Allow SSH from spicific CIDR or IP address"
      protocol    = "tcp"
    }
    http = {
      cidr        = "10.0.0.0/24"
      from_port   = 80
      to_port     = 80
      description = "Allow HTTP from spicific CIDR or IP address"
      protocol    = "tcp"
    }
    https = {
      cidr        = "10.0.0.0/24"
      from_port   = 443
      to_port     = 443
      description = "Allow HTTPS from spicific CIDR or IP address"
      protocol    = "tcp"
    }
  }
}

variable "security_group_rules_security_group_id" {
  description = "Map of security group rules with Security Group Id, port, and description"
  type = map(object({
    sec_group_id = string
    from_port    = number
    to_port      = number
    description  = string
    protocol     = string
  }))
  default = {
    ssh = {
      sec_group_id = "sg-091f2edc4c7e88785"
      from_port    = 22
      to_port      = 22
      description  = "Allow SSH from XYZ resource"
      protocol     = "tcp"
    }
    http = {
      sec_group_id = "sg-0330684950b8346df"
      from_port    = 443
      to_port      = 443
      description  = "Allow HTTP from XYZ resource"
      protocol     = "tcp"
    }
    https = {
      sec_group_id = "sg-0dcf4141c6f37d67f"
      from_port    = 443
      to_port      = 443
      description  = "Allow HTTPS from XYZ resource"
      protocol     = "tcp"
    }
  }
}

variable "security_group_rules_prefix_list_id" {
  description = "Map of security group rules with Prefix List, port, and description"
  type = map(object({
    prefix_list_id = string
    from_port      = number
    to_port        = number
    description    = string
    protocol       = string
  }))
  default = {
    http = {
      prefix_list_id = "pl-b6a144df"
      from_port      = 80
      to_port        = 80
      description    = "Allow HTTP from Cloudfront"
      protocol       = "tcp"
    }
    https = {
      prefix_list_id = "pl-b6a144df"
      from_port      = 443
      to_port        = 443
      description    = "Allow HTTPS from Cloudfront"
      protocol       = "tcp"
    }
  }
}

# ECS
variable "ecs_cluster_id" {
  description = "ECS cluster ID."
  type        = string
  default     = "arn:aws:ecs:us-east-1:841162703316:cluster/myprojectmy-workload-dev-ecs-cluster"
}

# ECS Task
variable "task_family" {
  description = "Family of the ECS task definition."
  type        = string
  default     = "my-workload-nginx"
}

variable "task_cpu" {
  description = "The number of CPU units for the task."
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "The amount of memory (in MiB) to allocate for the task."
  type        = string
  default     = "1024"
}

variable "network_mode" {
  description = "The Docker networking mode to use for the containers in the task."
  type        = string
  default     = "awsvpc"
}

variable "compatibilities" {
  description = "The launch types the task definition is compatible with."
  type        = list(string)
  default     = ["FARGATE"]
}

variable "managed_policies" {
  description = "List of managed policy ARNs to attach to the ECS task role."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"]
}

variable "task_role_policy" {
  description = "IAM Policy document for the ECS task role in JSON format."
  type        = string
  default     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeTasks",
        "ecs:UpdateTaskExecution"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "application-autoscaling:*",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:EnableAlarmActions",
          "iam:CreateServiceLinkedRole",
          "sns:CreateTopic",
          "sns:Subscribe",
          "sns:Get*",
          "sns:List*"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

# Container Configuration
variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "nginx-svc"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory (in MiB) for the container"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port that the container exposes"
  type        = number
  default     = 80
}

variable "host_port" {
  description = "Host port to map to container port"
  type        = number
  default     = 80
}

variable "container_essential" {
  description = "Whether the container is essential"
  type        = bool
  default     = true
}

variable "container_environment_variables" {
  description = "Map of environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "exec_role_arn" {
  description = "Execution role ARN."
  type        = string
  default     = "arn:aws:iam::841162703316:role/ecs-myprojectmy-workload-dev-task-exec-iam-role"
}

# ECS Service
variable "desired_count" {
  description = "The number of tasks to run."
  type        = number
  default     = 1
}

variable "use_existing_namespace" {
  description = "Indicates whether to use an existing Service Discovery namespace or create a new one"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "The app namespace to deploy the resources and local DNS."
  type        = string
  default     = "my-workload"
}

variable "force_new_deployment" {
  description = "This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest."
  type        = bool
  default     = true
}

variable "launch_type" {
  description = "The launch type on which to run your ECS service."
  type        = string
  default     = "FARGATE"
}

variable "subnets" {
  description = "List of subnet IDs for the service."
  type        = list(string)
  default     = ["subnet-0521aa00427d156e0", "subnet-0854fca60e5b9ef64"]
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ECS service."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-0db92d66d4dd147da"
  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,63}$", var.vpc_id))
    error_message = "The VPC ID format is invalid. It should follow the pattern 'vpc-XXXXXXXX'."
  }
}

variable "alb_listener_arn" {
  description = "ARN ALB Listener."
  type        = string
  default     = "arn:aws:elasticloadbalancing:us-east-1:841162703316:loadbalancer/net/myprojectmy-workload-dev/18a9a0132121ceeb"
}

variable "target_type" {
  description = "Target type: instance, ip, lambda or alb."
  type        = string
  default     = "ip"
}

variable "target_group_protocol" {
  description = "Protocol for the Target Group: HTTP or HTTPS"
  type        = string
  default     = "HTTP"
}

variable "alb_listener_rules" {
  description = "ALB listener rules configuration. IMPORTANT: The service names (keys) in this map must match the container names defined in the container_name variable, as they are used for target group mapping."
  type = map(map(object({
    priority = number
    conditions = list(object({
      type   = string
      values = list(string)
      key    = optional(string)
    }))
  })))
}

variable "health_check_path" {
  description = "Path health_check ALB"
  type        = string
  default     = "/health"
}

# Autoscaling
variable "max_cpu_threshold" {
  description = "Threshold for max CPU usage"
  default     = "85"
  type        = string
}

variable "min_cpu_threshold" {
  description = "Threshold for min CPU usage"
  default     = "10"
  type        = string
}

variable "max_cpu_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold for max cpu metric alarm"
  default     = "3"
  type        = string
}

variable "min_cpu_evaluation_period" {
  description = "The number of periods over which data is compared to the specified threshold for min cpu metric alarm"
  default     = "3"
  type        = string
}

variable "max_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for max cpu metric alarm"
  default     = "60"
  type        = string
}

variable "min_cpu_period" {
  description = "The period in seconds over which the specified statistic is applied for min cpu metric alarm"
  default     = "60"
  type        = string
}

variable "scale_target_max_capacity" {
  description = "The max capacity of the scalable target"
  default     = 5
  type        = number
}

variable "scale_target_min_capacity" {
  description = "The min capacity of the scalable target"
  default     = 1
  type        = number
}

variable "sns_topic_arn" {
  type        = string
  description = "The ARN of an SNS topic to send notifications on alarm actions."
  default     = ""
}

variable "cooldown" {
  description = "Cooldown period for scaling actions"
  type        = number
  default     = 60
}

# Circuit Breaker Configuration
variable "circuit_breaker_enabled" {
  description = "Enable circuit breaker functionality"
  type        = bool
  default     = true
}

variable "circuit_breaker_error_threshold" {
  description = "Error rate threshold to trigger circuit breaker (percentage)"
  type        = number
  default     = 50
}

variable "circuit_breaker_evaluation_periods" {
  description = "Number of periods to evaluate for circuit breaker"
  type        = number
  default     = 2
}

variable "circuit_breaker_period" {
  description = "Period in seconds for circuit breaker evaluation"
  type        = number
  default     = 60
}

# Tags
variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

# Cloudwatch logs 
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data. If not provided, logs will not be encrypted."
  type        = string
  default     = null
  validation {
    condition = var.kms_key_id == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}$", var.kms_key_id))
    error_message = "KMS Key ID must be a valid KMS key ARN format or null."
  }
}
