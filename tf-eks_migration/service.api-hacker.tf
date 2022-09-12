resource "aws_ecr_repository" "api-hacker" {
  name = "api-hacker"
}

resource "aws_alb_target_group" "api-hacker" {
  name        = "api-hacker"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    port     = 5000
    interval = 5
    timeout  = 3
    path     = "/hacker/v1/health"
    matcher  = "200"
  }
}

resource "aws_ecs_task_definition" "api-hacker" {
  family                   = "api-hacker"
  #container_definitions   = file("task/api-hacker.json")
  container_definitions    = templatefile("task/api-hacker.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
  task_role_arn            = aws_iam_role.api-hacker-task.arn

  tags = {}
}

resource "aws_ecs_service" "api-hacker" {
  name             = "api-hacker"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.api-hacker.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.api-hacker.arn
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
      aws_security_group.api-hacker.id
    ]
  }
}

resource "aws_security_group" "api-hacker" {
  name        = "api-hacker"
  description = "api-hacker"
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

resource "aws_lb_listener_rule" "api-hacker" {
  listener_arn = aws_alb_listener.platform.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api-hacker.arn
  }

  condition {
    path_pattern {
      values = ["/hacker/v1/*"]
    }
  }
}

resource "aws_iam_user" "api-hacker" {
  name = "hackedu-api-hacker"
  path = "/"
}

resource "aws_iam_user_policy" "api-hacker-policy" {
  name = "api-hacker-policy"
  user = aws_iam_user.api-hacker.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cognito-idp:DescribeIdentityProvider",
        "cognito-idp:CreateIdentityProvider",
        "cognito-idp:DescribeUserPoolClient",
        "cognito-idp:UpdateIdentityProvider",
        "cognito-idp:UpdateUserPoolClient",
        "cognito-idp:AdminUpdateUserAttributes",
        "ses:SendEmail",
        "ses:SendTemplatedEmail",
        "ses:SendRawEmail",
        "sqs:SendMessage",
        "sqs:SendMessageBatch",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListQueues",
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "api-hacker-task" {
  name = "platform-api-hacker-task"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
