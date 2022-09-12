resource "aws_ecr_repository" "api-health" {
  name = "api-health"
}

resource "aws_alb_target_group" "api-health" {
  name        = "api-health"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    port     = 5000
    interval = 5
    timeout  = 3
    path     = "/health/v1/health"
    matcher  = "200"
  }
}

resource "aws_lb_listener_rule" "api-health" {
  listener_arn = aws_alb_listener.platform.arn
  priority     = 140

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-health.arn
  }

  condition {
    path_pattern {
      values = ["/health/v1/*"]
    }
  }
}

resource "aws_ecs_task_definition" "api-health" {
  family                   = "api-health"
  # container_definitions    = file("task/api-health.json")
  container_definitions    = templatefile("task/api-health.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
  task_role_arn            = aws_iam_role.api-hacker-task.arn

  tags = {}
}

resource "aws_ecs_service" "api-health" {
  name             = "api-health"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-health.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-health.arn
    container_name   = "app"
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
      aws_security_group.api-health.id
    ]
  }
}

resource "aws_security_group" "api-health" {
  name        = "api-health"
  description = "api-health"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    description     = "Allow inbound traffic from load balancer"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.traefik-alb.id]
  }

  egress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.tag-api.id]
  }
}

# api-health
resource "aws_iam_user" "api-health" {
  name = "hackedu-api-health"
  path = "/"
}

resource "aws_iam_user_policy" "api-health-policy" {
  name = "api-health-policy"
  user = aws_iam_user.api-health.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
      "Effect": "Allow",
      "Action": [
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
      ],
      "Resource": "*"
  }
  ]
}
EOF
}
