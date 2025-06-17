output "service_endpoints" {
  description = "Service endpoints for AI service"
  value       = module.ai_service.service_connect_endpoints
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ai_service.ecs_task_definition_arn
}

output "service_names" {
  description = "Names of the ECS services"
  value       = module.ai_service.ecs_service_names
}