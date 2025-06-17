output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.ecs_task.arn
  description = "ARN of the ECS Task Definition"
}

output "ecs_service_names" {
  value       = { for k, service in aws_ecs_service.ecs_service : k => service.name }
  description = "Names of the ECS Services created"
}

output "sec_group_id" {
  value       = aws_security_group.main.id
  description = "ID of the Security Group"
}