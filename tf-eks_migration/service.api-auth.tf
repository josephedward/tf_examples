resource "aws_ecr_repository" "api-auth" {
  name = "api-auth"
}

resource "aws_lb_listener_rule" "api-auth" {
  listener_arn = aws_alb_listener.platform.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-auth.arn
  }

  condition {
    path_pattern {
      values = ["/auth/v1/*"]
    }
  }
}

resource "aws_alb_target_group" "api-auth" {
  name        = "api-auth"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    port     = 5000
    interval = 5
    timeout  = 3
    path     = "/auth/v1/health"
    matcher  = "200"
  }
}

resource "aws_ecs_task_definition" "api-auth" {
  family                = "api-auth"
  container_definitions = templatefile(
    "task/api-auth.json", {
      secret                = var.secret,
      public                = var.public,
      cognito-user-pool-id  = aws_cognito_user_pool.hackedu.id,
      cognito-client-id     = aws_cognito_user_pool_client.app.id,
      db_host               = aws_db_instance.platform.address
  })
  requires_compatibilities  = ["FARGATE"]
  cpu                       = "256"
  memory                    = "512"
  network_mode              = "awsvpc"
  execution_role_arn        = aws_iam_role.router-execution.arn
  task_role_arn             = aws_iam_role.api-hacker-task.arn

  tags = {}

}

resource "aws_ecs_service" "api-auth" {
  name             = "api-auth"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-auth.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-auth.arn
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
      aws_security_group.api-auth.id
    ]
  }
}

resource "aws_security_group" "api-auth" {
  name        = "api-auth"
  description = "api-auth"
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


# ECS task role for api-auth
resource "aws_iam_user" "api-auth" {
  name = "hackedu-api-auth"
  path = "/"
}

# TODO: Variable for user pool id (see below)
#"Resource": [
#  "${data.terraform_remote_state.base.outputs.cognito-user-pool-arn}"
#]
resource "aws_iam_user_policy" "api-auth-policy" {
  name = "api-auth-policy"
  user = aws_iam_user.api-auth.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
      "Effect": "Allow",
      "Action": [
          "cognito-idp:GetIdentityProviderByIdentifier",
          "cognito-idp:ListIdentityProviders",
          "cognito-idp:DescribeUserPoolClient"
      ],
      "Resource": [
        "arn:aws:cognito-idp:us-east-1:${var.public.account_id}:userpool/${var.public.cognito.user_pool_id}"
      ]
  }
  ]
}
EOF
}
