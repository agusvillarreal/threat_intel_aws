# Data Sources
data "aws_caller_identity" "current" {}

# S3 Bucket for OpenCTI data
resource "aws_s3_bucket" "opencti_data" {
  bucket = "${var.name}-opencti-data"

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-data"
  })
}

resource "aws_s3_bucket_versioning" "opencti_data" {
  bucket = aws_s3_bucket.opencti_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "opencti_data" {
  bucket = aws_s3_bucket.opencti_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "opencti_data" {
  bucket = aws_s3_bucket.opencti_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# EFS File System for persistent storage
resource "aws_efs_file_system" "opencti_storage" {
  creation_token = "${var.name}-opencti-storage"
  encrypted      = true

  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 100

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-storage"
  })
}

# EFS Mount Targets
resource "aws_efs_mount_target" "opencti_storage" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.opencti_storage.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}

# EFS Access Point for OpenCTI
resource "aws_efs_access_point" "opencti_data" {
  file_system_id = aws_efs_file_system.opencti_storage.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/opencti"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-access-point"
  })
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name}-cache-subnet"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name}-cache-subnet-group"
  })
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${var.name}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-redis-params"
  })
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name}-redis"
  description          = "Redis cluster for OpenCTI"

  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.elasticache_security_group_id]

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  tags = merge(var.common_tags, {
    Name = "${var.name}-redis"
  })
}

# OpenSearch Service-Linked Role
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "es.amazonaws.com"
}

# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.name}-opensearch"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type            = "t3.small.search"
    instance_count           = 1
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }

  vpc_options {
    subnet_ids         = [var.private_subnet_ids[0]]
    security_group_ids = [var.opensearch_security_group_id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.fielddata.cache.size"           = "20"
    "indices.query.bool.max_clause_count"    = "1024"
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.name}-opensearch/*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name}-opensearch"
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}

# Amazon MQ for RabbitMQ
resource "aws_mq_broker" "rabbitmq" {
  broker_name             = "${var.name}-rabbitmq"
  engine_type             = "RabbitMQ"
  engine_version          = "3.13"
  host_instance_type      = "mq.t3.micro"
  security_groups         = [var.rabbitmq_security_group_id]
  subnet_ids              = [var.private_subnet_ids[0]]
  auto_minor_version_upgrade = true

  user {
    username = "admin"
    password = "ChangeMeRabbitMQ123"
  }

  logs {
    general = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-rabbitmq"
  })
}
