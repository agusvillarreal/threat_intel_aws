provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = data.aws_availability_zones.available.names
  common_tags          = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  name                          = local.name
  aws_region                    = var.aws_region
  aws_account_id                = data.aws_caller_identity.current.account_id
  vpc_cidr                      = var.vpc_cidr
  private_subnet_ids            = module.networking.private_subnet_ids
  efs_security_group_id         = module.networking.efs_security_group_id
  elasticache_security_group_id = module.networking.elasticache_security_group_id
  opensearch_security_group_id  = module.networking.opensearch_security_group_id
  rabbitmq_security_group_id    = module.networking.rabbitmq_security_group_id
  common_tags                   = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  name                        = local.name
  vpc_id                      = module.networking.vpc_id
  public_subnet_ids           = module.networking.public_subnet_ids
  private_subnet_ids          = module.networking.private_subnet_ids
  alb_security_group_id       = module.networking.alb_security_group_id
  ecs_tasks_security_group_id = module.networking.ecs_tasks_security_group_id
  s3_bucket_arn               = module.storage.s3_bucket_arn
  s3_bucket_id                = module.storage.s3_bucket_id
  common_tags                 = local.common_tags
}

# Services Module
module "services" {
  source = "./modules/services"

  name                           = local.name
  aws_region                     = var.aws_region
  ecs_cluster_id                 = module.compute.ecs_cluster_id
  private_subnet_ids             = module.networking.private_subnet_ids
  ecs_tasks_security_group_id    = module.networking.ecs_tasks_security_group_id
  ecs_task_execution_role_arn    = module.compute.ecs_task_execution_role_arn
  ecs_task_role_arn              = module.compute.ecs_task_role_arn
  alb_dns_name                   = module.compute.alb_dns_name
  alb_listener_arn               = module.compute.alb_listener_arn
  opencti_target_group_arn       = module.compute.opencti_target_group_arn
  efs_file_system_id             = module.storage.efs_file_system_id
  efs_access_point_id            = module.storage.efs_access_point_id
  s3_bucket_name                 = module.storage.s3_bucket_id
  opensearch_endpoint            = module.storage.opensearch_endpoint
  redis_endpoint                 = module.storage.redis_endpoint
  redis_port                     = module.storage.redis_port
  rabbitmq_endpoint              = module.storage.rabbitmq_endpoint
  opencti_admin_email            = var.opencti_admin_email
  opencti_admin_password         = var.opencti_admin_password
  common_tags                    = local.common_tags
}
