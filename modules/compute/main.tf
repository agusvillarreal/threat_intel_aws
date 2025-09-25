# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-cluster"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "opencti" {
  name              = "/ecs/${var.name}/opencti"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-logs"
  })
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.name}/redis"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name}-redis-logs"
  })
}

resource "aws_cloudwatch_log_group" "rabbitmq" {
  name              = "/ecs/${var.name}/rabbitmq"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name}-rabbitmq-logs"
  })
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.name}/worker"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name}-worker-logs"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.name}-alb"
  })
}

# Target Group for OpenCTI
resource "aws_lb_target_group" "opencti" {
  name        = "${var.name}-opencti-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-tg"
  })
}

# ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.opencti.arn
  }
}

# Cloud Map Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "opencti.local"
  description = "OpenCTI service discovery namespace"
  vpc         = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name}-cloudmap-namespace"
  })
}

# Service Discovery Services
resource "aws_service_discovery_service" "redis" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }


  tags = merge(var.common_tags, {
    Name = "${var.name}-redis-service"
  })
}

resource "aws_service_discovery_service" "rabbitmq" {
  name = "rabbitmq"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }


  tags = merge(var.common_tags, {
    Name = "${var.name}-rabbitmq-service"
  })
}

resource "aws_service_discovery_service" "opencti" {
  name = "opencti"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }


  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-service"
  })
}
