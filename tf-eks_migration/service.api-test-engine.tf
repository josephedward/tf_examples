resource "aws_ecr_repository" "api-test-engine-api" {
  name = "platform/test-engine/api"
}
resource "aws_ecr_repository" "api-test-engine-worker" {
  name = "platform/test-engine/worker"
}

resource "aws_alb_target_group" "api-test-engine" {
  name        = "api-test-engine"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    port     = 5000
    interval = 5
    timeout  = 3
    path     = "/test-engine/v1/health"
    matcher  = "200"
  }
}

resource "aws_lb_listener_rule" "api-test-engine" {
  listener_arn = aws_alb_listener.platform.arn
  priority     = 180

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-test-engine.arn
  }

  condition {
    path_pattern {
      values = ["/test-engine/v1/*"]
    }
  }
}

resource "aws_route53_record" "api-test-engine-queue-private" {
  zone_id = aws_route53_zone.hackedu-private.id
  name    = var.public.private_urls.test-engine-queue
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_elasticache_cluster.test-engine.cache_nodes.0.address ]
}

resource "aws_ecs_task_definition" "api-test-engine" {
  family                   = "api-test-engine"
  container_definitions    = templatefile("task/api-test-engine.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
  task_role_arn            = aws_iam_role.router-task.arn
}

resource "aws_ecs_service" "api-test-engine" {
  name             = "api-test-engine"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-test-engine.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-test-engine.arn
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
      aws_security_group.api-test-engine.id
    ]
  }
}

resource "aws_security_group" "api-test-engine" {
  name = "api-test-engine"
  description = "api-test-engine security group"
  vpc_id = aws_vpc.hackedu.id

  ingress {
    description = "open inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "outbound https access"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "database access"
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.tag-api.id]
  }

  egress {
    description = "sandbox access"
    from_port   = 32768
    to_port     = 61000
    protocol    = "TCP"

    // TODO: Lock this down to just sandboxes
    cidr_blocks = [
      aws_vpc.hackedu.cidr_block
    ]
  }
}
