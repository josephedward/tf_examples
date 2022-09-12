resource "aws_ecr_repository" "api-linter" {
  name = "api-linter"
}

resource "aws_alb_target_group" "api-linter" {
  name        = "api-linter"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    port     = 5000
    interval = 5
    timeout  = 3
    path     = "/linter/v1/health"
    matcher  = "200"
  }
}

resource "aws_lb_listener_rule" "api-linter" {
  listener_arn = aws_alb_listener.platform.arn
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-linter.arn
  }

  condition {
    path_pattern {
      values = ["/linter/v1/*"]
    }
  }
}

resource "aws_elasticache_cluster" "api-linter" {
  cluster_id           = "api-linter"
  engine               = "redis"
  node_type            = "cache.t3.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.production.id

  security_group_ids = [
    aws_security_group.router.id,
    aws_security_group.router-tag.id,
    aws_security_group_rule.flask-api-ingress-from-public.id,
    aws_security_group.elasticache-internal.id,
  ]
}

resource "aws_ecs_task_definition" "api-linter" {
  family                   = "api-linter"
  container_definitions    = templatefile("task/api-linter.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
  task_role_arn            = aws_iam_role.router-task.arn
}

resource "aws_ecs_service" "api-linter" {
  name             = "api-linter"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-linter.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-linter.arn
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
      aws_security_group.api-linter.id
    ]
  }
}

resource "aws_security_group" "api-linter" {
  name        = "api-linter"
  description = "api-linter"
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

resource "aws_route53_record" "redis-linter" {
  zone_id = aws_route53_zone.hackedu-private.zone_id
  name    = var.public.api-linter.redis_url_base
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_elasticache_cluster.api-linter.cache_nodes.0.address ]
}
