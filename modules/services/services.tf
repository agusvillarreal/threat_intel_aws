
# OpenCTI Service
resource "aws_ecs_service" "opencti" {
  name            = "${var.name}-opencti"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.opencti.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_tasks_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }


  load_balancer {
    target_group_arn = var.opencti_target_group_arn
    container_name   = "opencti"
    container_port   = 8080
  }

  depends_on = [var.alb_listener_arn]

  tags = merge(var.common_tags, {
    Name = "${var.name}-opencti-service"
  })
}

# Worker Service
resource "aws_ecs_service" "worker" {
  name            = "${var.name}-worker"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [var.ecs_tasks_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  depends_on = [aws_ecs_service.opencti]

  tags = merge(var.common_tags, {
    Name = "${var.name}-worker-service"
  })
}
