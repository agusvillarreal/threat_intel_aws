# Random UUIDs for connectors
resource "random_uuid" "connector_history_id" {}
resource "random_uuid" "connector_export_file_stix_id" {}
resource "random_uuid" "connector_export_file_csv_id" {}
resource "random_uuid" "connector_import_file_stix_id" {}
resource "random_uuid" "connector_export_file_txt_id" {}
resource "random_uuid" "connector_import_document_id" {}
resource "random_uuid" "connector_analysis_id" {}
resource "random_uuid" "opencti_healthcheck_access_key" {}

# Generate a proper UUID string for OpenCTI admin token
locals {
  opencti_admin_token = "550e8400-e29b-41d4-a716-446655440000"
}


# OpenCTI Task Definition
resource "aws_ecs_task_definition" "opencti" {
  family                   = "${var.name}-opencti"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  volume {
    name = "opencti-storage"
    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = "opencti"
      image = "opencti/platform:6.7.20"

      essential = true
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}/opencti"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_OPTIONS"
          value = "--max-old-space-size=4096"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "APP__PORT"
          value = "8080"
        },
        {
          name  = "APP__HOST"
          value = "0.0.0.0"
        },
        {
          name  = "APP__BASE_URL"
          value = "http://${var.alb_dns_name}"
        },
        {
          name  = "APP__ADMIN__EMAIL"
          value = var.opencti_admin_email
        },
        {
          name  = "APP__ADMIN__PASSWORD"
          value = var.opencti_admin_password
        },
        {
          name  = "APP__ADMIN__TOKEN"
          value = local.opencti_admin_token
        },
        {
          name  = "APP__ADMIN__TOKEN__EXPIRATION"
          value = "false"
        },
        {
          name  = "APP__APP_LOGS__LOGS_LEVEL"
          value = "error"
        },
        {
          name  = "APP__APP_LOGS__LOGS_LEVEL__CONSOLE"
          value = "error"
        },
        {
          name  = "APP__APP_LOGS__LOGS_LEVEL__FILE"
          value = "error"
        },
        {
          name  = "REDIS__HOSTNAME"
          value = var.redis_endpoint
        },
        {
          name  = "REDIS__PORT"
          value = var.redis_port
        },
        {
          name  = "ELASTICSEARCH__URL"
          value = "https://${var.opensearch_endpoint}"
        },
        {
          name  = "ELASTICSEARCH__NUMBER_OF_REPLICAS"
          value = "0"
        },
        {
          name  = "MINIO__ENDPOINT"
          value = "s3.${var.aws_region}.amazonaws.com"
        },
        {
          name  = "MINIO__PORT"
          value = "443"
        },
        {
          name  = "MINIO__USE_SSL"
          value = "true"
        },
        {
          name  = "MINIO__BUCKET_NAME"
          value = var.s3_bucket_name
        },
        {
          name  = "MINIO__USE_AWS_ROLE"
          value = "true"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        },
        {
          name  = "RABBITMQ__HOSTNAME"
          value = replace(replace(var.rabbitmq_endpoint, "amqps://", ""), ":5671", "")
        },
        {
          name  = "RABBITMQ__PORT"
          value = "5671"
        },
        {
          name  = "RABBITMQ__USE_SSL"
          value = "true"
        },
        {
          name  = "RABBITMQ__PORT_MANAGEMENT"
          value = "15671"
        },
        {
          name  = "RABBITMQ__MANAGEMENT_SSL"
          value = "true"
        },
        {
          name  = "RABBITMQ__USE_SSL"
          value = "true"
        },
        {
          name  = "RABBITMQ__USERNAME"
          value = "admin"
        },
        {
          name  = "RABBITMQ__PASSWORD"
          value = "ChangeMeRabbitMQ123"
        },
        {
          name  = "SMTP__HOSTNAME"
          value = "localhost"
        },
        {
          name  = "SMTP__PORT"
          value = "25"
        },
        {
          name  = "PROVIDERS__LOCAL__STRATEGY"
          value = "LocalStrategy"
        },
        {
          name  = "APP__HEALTH_ACCESS_KEY"
          value = random_uuid.opencti_healthcheck_access_key.result
        },
        {
          name  = "CONNECTOR_HISTORY_ID"
          value = random_uuid.connector_history_id.result
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "opencti-storage"
          containerPath = "/opt/opencti/storage"
          readOnly      = false
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 180
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}/opencti"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-task"
  })
}

# Worker Task Definition
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.name}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  volume {
    name = "opencti-storage"
    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = "worker"
      image = "opencti/worker:6.7.20"

      environment = [
        {
          name  = "OPENCTI_URL"
          value = "http://opencti.opencti.local:8080"
        },
        {
          name  = "OPENCTI_TOKEN"
          value = local.opencti_admin_token
        },
        {
          name  = "WORKER_LOG_LEVEL"
          value = "info"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "opencti-storage"
          containerPath = "/opt/opencti/storage"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}/worker"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name}-worker-task"
  })
}
