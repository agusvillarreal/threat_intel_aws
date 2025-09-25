output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "opencti_url" {
  description = "OpenCTI application URL"
  value       = "http://${module.compute.alb_dns_name}"
}

output "cloud_map_namespace_id" {
  description = "Cloud Map namespace ID"
  value       = module.compute.cloud_map_namespace_id
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.compute.ecs_cluster_id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.s3_bucket_id
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = module.storage.efs_file_system_id
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.storage.redis_endpoint
}

output "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  value       = module.storage.opensearch_endpoint
}
