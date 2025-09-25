
output "opencti_task_definition_arn" {
  description = "ARN of the OpenCTI task definition"
  value       = aws_ecs_task_definition.opencti.arn
}

output "worker_task_definition_arn" {
  description = "ARN of the Worker task definition"
  value       = aws_ecs_task_definition.worker.arn
}


output "opencti_service_id" {
  description = "ID of the OpenCTI service"
  value       = aws_ecs_service.opencti.id
}

output "worker_service_id" {
  description = "ID of the Worker service"
  value       = aws_ecs_service.worker.id
}
