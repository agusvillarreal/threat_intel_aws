output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.main.arn
}

output "opencti_target_group_arn" {
  description = "ARN of the OpenCTI target group"
  value       = aws_lb_target_group.opencti.arn
}

output "cloud_map_namespace_id" {
  description = "Cloud Map namespace ID"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "redis_service_discovery_arn" {
  description = "Redis service discovery ARN"
  value       = aws_service_discovery_service.redis.arn
}

output "rabbitmq_service_discovery_arn" {
  description = "RabbitMQ service discovery ARN"
  value       = aws_service_discovery_service.rabbitmq.arn
}

output "opencti_service_discovery_arn" {
  description = "OpenCTI service discovery ARN"
  value       = aws_service_discovery_service.opencti.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}
