locals {
  environment_map = {
    development = "dev"
    test        = "test"
    production  = "prod"
    betaqa      = "betaqa"
    staging     = "stg"
    sandbox     = "sandbox"
  }
  
  # Container definitions
  container_definitions = [
    {
      name      = var.container_name
      image     = var.container_image
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = var.container_essential
      environment = [
        for key, value in var.container_environment_variables : {
          name  = key
          value = value
        }
      ]
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
          name          = var.container_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ]
  
  target_group_map = {
    for idx, container in local.container_definitions : container.name => idx
  }
}

data "aws_region" "current" {}

# Security Group
resource "aws_security_group" "main" {
  vpc_id      = var.vpc_id
  description = "Security group for the ${var.project_name} resource/service"
  name        = "${var.project_name}-sg"
  tags = merge(var.tags, {
    "Name" = "${var.project_name}-${local.environment_map[var.environment]}-sg"
  })

  dynamic "ingress" {
    for_each = var.security_group_rules_cidrs
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
      description = ingress.value.description
    }
  }

  dynamic "ingress" {
    for_each = var.security_group_rules_security_group_id
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = [ingress.value.sec_group_id]
      description     = ingress.value.description
    }
  }

  dynamic "ingress" {
    for_each = var.security_group_rules_prefix_list_id
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      prefix_list_ids = [ingress.value.prefix_list_id]
      description     = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.security_group_rules_cidrs
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = [egress.value.cidr]
      description = egress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.security_group_rules_security_group_id
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      security_groups = [egress.value.sec_group_id]
      description     = egress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.security_group_rules_prefix_list_id
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      prefix_list_ids = [egress.value.prefix_list_id]
      description     = egress.value.description
    }
  }
}


# ECS task Role
resource "aws_iam_role" "task_role" {
  name = "ecs-${var.project_name}-${local.environment_map[var.environment]}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "task_role_policy" {
  name   = "ecs-${var.project_name}-${local.environment_map[var.environment]}-task-policy"
  policy = var.task_role_policy
}

resource "aws_iam_role_policy_attachment" "task_role_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "managed_policy_attachment" {
  count      = length(var.managed_policies)
  role       = aws_iam_role.task_role.name
  policy_arn = element(var.managed_policies, count.index)
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = var.task_family
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = var.network_mode
  requires_compatibilities = var.compatibilities
  container_definitions    = jsonencode(local.container_definitions)
  execution_role_arn       = aws_iam_role.task_role.arn
  task_role_arn            = var.exec_role_arn
  tags                     = var.tags
}

# ALB Target Groups 
resource "aws_lb_target_group" "alb" {
  count       = length(local.container_definitions)
  name        = "${substr("${var.project_name}-${local.environment_map[var.environment]}-${replace(local.container_definitions[count.index].name, "-", "")}", 0, 28)}-tg"
  port        = local.container_definitions[count.index].portMappings[0].containerPort
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    path                = var.health_check_path
    enabled             = true
    interval            = 20
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 19
    matcher             = "200-499"
  }

  tags = merge(var.tags, {
    "Name" = "${var.project_name}-${local.environment_map[var.environment]}-${local.container_definitions[count.index].name}-alb-tg"
  })
}

resource "aws_lb_listener_rule" "main_alb" {
  for_each = tomap({
    for rule in flatten([
      for svc_name, rules in var.alb_listener_rules :
      [for rule_name, rule in rules :
        {
          id         = "${svc_name}-${rule_name}"
          svc_name   = svc_name
          priority   = rule.priority
          conditions = rule.conditions
        }
      ]
    ]) : rule.id => rule
  })

  listener_arn = var.alb_listener_arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb[lookup(local.target_group_map, each.value.svc_name)].arn
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      # Build dynamic condition blocks based on condition type
      dynamic "path_pattern" {
        for_each = condition.value.type == "path_pattern" ? [condition.value] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "host_header" {
        for_each = condition.value.type == "host_header" ? [condition.value] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.type == "http_header" ? [condition.value] : []
        content {
          http_header_name = http_header.value.key
          values           = http_header.value.values
        }
      }

      dynamic "http_request_method" {
        for_each = condition.value.type == "http_request_method" ? [condition.value] : []
        content {
          values = http_request_method.value.values
        }
      }

      dynamic "query_string" {
        for_each = condition.value.type == "query_string" ? [for v in condition.value.values : { key = condition.value.key, value = v }] : []
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = condition.value.type == "source_ip" ? [condition.value] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }
}

# Data source for existing namespace if use_existing_namespace is true
data "aws_service_discovery_dns_namespace" "existing" {
  count = var.use_existing_namespace ? 1 : 0

  name = "${var.namespace}.${local.environment_map[var.environment]}.local"
  type = "DNS_PRIVATE"
}

# Resource for creating namespace if use_existing_namespace is false
resource "aws_service_discovery_private_dns_namespace" "namespace" {
  count = var.use_existing_namespace ? 0 : 1

  name        = "${var.namespace}.${local.environment_map[var.environment]}.local"
  vpc         = var.vpc_id
  description = "Private DNS namespace for ${var.project_name}"
  tags        = var.tags
}

# ECS Service for each container
resource "aws_ecs_service" "ecs_service" {
  for_each = { for idx, container in local.container_definitions : container.name => container }

  name            = "${var.project_name}-${local.environment_map[var.environment]}-${each.key}-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = var.desired_count
  launch_type     = var.launch_type

  # Add explicit dependency on listener rules
  depends_on = [aws_lb_listener_rule.main_alb]

  load_balancer {
    target_group_arn = aws_lb_target_group.alb[lookup(local.target_group_map, each.key)].arn
    container_name   = each.value.name
    container_port   = each.value.portMappings[0].containerPort
  }

  network_configuration {
    subnets          = var.subnets
    assign_public_ip = var.assign_public_ip
    security_groups  = [aws_security_group.main.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.use_existing_namespace ? data.aws_service_discovery_dns_namespace.existing[0].arn : aws_service_discovery_private_dns_namespace.namespace[0].arn

    service {
      port_name = each.value.portMappings[0].name
      client_alias {
        port     = each.value.portMappings[0].containerPort
        dns_name = each.key
      }
    }
  }

  tags = merge(var.tags, {
    "Name" = "${var.project_name}-${local.environment_map[var.environment]}-${each.key}-service"
  })
}

# Scaling Target for each ECS Service
resource "aws_appautoscaling_target" "scale_target" {
  for_each = aws_ecs_service.ecs_service

  service_namespace  = "ecs"
  resource_id        = "service/${element(split("/", var.ecs_cluster_id), 1)}/${aws_ecs_service.ecs_service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.scale_target_min_capacity
  max_capacity       = var.scale_target_max_capacity
}

# Scaling Up Policy for each ECS Service
resource "aws_appautoscaling_policy" "scale_up_policy" {
  for_each = aws_ecs_service.ecs_service

  name               = "${each.key}-scale-up-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.scale_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target[each.key].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Maximum"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# Scaling Down Policy for each ECS Service
resource "aws_appautoscaling_policy" "scale_down_policy" {
  for_each = aws_ecs_service.ecs_service

  name               = "${each.key}-scale-down-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.scale_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target[each.key].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Maximum"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# CloudWatch Alarm CPU High for each ECS Service
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = aws_ecs_service.ecs_service

  alarm_name          = "${each.key}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.max_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.max_cpu_period
  statistic           = "Maximum"
  threshold           = var.max_cpu_threshold
  dimensions = {
    ClusterName = element(split("/", var.ecs_cluster_id), 1)
    ServiceName = aws_ecs_service.ecs_service[each.key].name
  }
  alarm_actions = compact([
    aws_appautoscaling_policy.scale_up_policy[each.key].arn,
    var.sns_topic_arn != "" ? var.sns_topic_arn : ""
  ])
  tags = var.tags
}

# CloudWatch Alarm CPU Low for each ECS Service
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  for_each = aws_ecs_service.ecs_service

  alarm_name          = "${each.key}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.min_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.min_cpu_period
  statistic           = "Average"
  threshold           = var.min_cpu_threshold
  dimensions = {
    ClusterName = element(split("/", var.ecs_cluster_id), 1)
    ServiceName = aws_ecs_service.ecs_service[each.key].name
  }
  alarm_actions = compact([
    aws_appautoscaling_policy.scale_down_policy[each.key].arn,
    var.sns_topic_arn != "" ? var.sns_topic_arn : ""
  ])
  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.project_name}/${local.environment_map[var.environment]}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id
  
  tags = merge(var.tags, {
    "Name" = "${var.project_name}-${local.environment_map[var.environment]}-log-group"
  })
}
