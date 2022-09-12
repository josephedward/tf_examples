### Listener
resource "aws_lb_listener_rule" "api-public" {
  listener_arn = aws_alb_listener.public.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-public.arn
  }

  condition {
    host_header {
      values = [var.public.urls.api]
    }
  }
}

### Target Group
resource "aws_alb_target_group" "api-public" {
  name        = "api-public"
  port        = 6000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    interval = 15
    timeout  = 3
    path     = "/v1/health"
    matcher  = "200"
  }
}

### Route53
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = var.public.urls.api
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.public.dns_name]
}

### ECS Task
resource "aws_ecs_task_definition" "api-public" {
  family                   = "api-public"
  container_definitions    = templatefile("task/api-public.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn

  tags = {
    "name": "api-public"
  }
}

### ECS Service
resource "aws_ecs_service" "api-public" {
  name             = "api-public"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-public.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-public.arn
    container_name   = "app"
    container_port   = 6000
  }

  network_configuration {
    subnets = [
      aws_subnet.private-a.id,
      aws_subnet.private-b.id,
      aws_subnet.private-c.id
    ]

    security_groups = [
      aws_security_group_rule.flask-api-ingress-from-public.id,
      aws_security_group.pg-outbound-from-api.id,
      aws_security_group.public.id,
      aws_security_group.tag-api.id,
      aws_security_group.api-public.id
    ]
  }
}

resource "aws_security_group" "api-public" {
  name        = "api-public"
  description = "api-public"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    description     = "Allow inbound traffic from load balancer"
    from_port       = 6000
    to_port         = 6000
    protocol        = "tcp"
    security_groups = [aws_security_group.public-alb.id]
  }
}
