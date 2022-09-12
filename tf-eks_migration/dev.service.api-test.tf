resource "aws_ecr_repository" "api-test" {
  name = "api-test"
}

resource "aws_ecs_task_definition" "api-test" {
  family                   = "api-test"
  container_definitions    = templatefile("task/api-test.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
  task_role_arn            = aws_iam_role.api-hacker-task.arn

  tags = {}
}

resource "aws_ecs_service" "api-test" {
  name             = "api-test"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-test.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-test.arn
    container_name   = "api-test"
    container_port   = 5000
  }

  network_configuration {
    subnets = [
      aws_subnet.private-a.id,
      aws_subnet.private-b.id,
      aws_subnet.private-c.id
    ]
    
    security_groups = [
      aws_security_group.production-ecs-instance.id,
      aws_security_group.tag-api.id,
      aws_security_group_rule.flask-api-ingress-from-public.id,
      aws_security_group.pg-outbound-from-api.id
    ]
  }
}

resource "aws_alb_target_group" "api-test" {
  name        = "api-test"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    port     = 5000
    interval = 5
    timeout  = 3
    path     = "/test/v1/health"
    matcher  = "200"
  }
}

resource "aws_lb_listener_rule" "api-test" {
  listener_arn = aws_alb_listener.public.load_balancer_arn
  priority     = 170

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-test.arn
  }

  condition {
    path_pattern {
      values = ["/test/v1/*"]
    }
  }
}
