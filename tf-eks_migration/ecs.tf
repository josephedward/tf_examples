############
# Clusters #
############

resource "aws_ecs_cluster" "platform" {
  name = "platform"
}

############
# SERVICES #
############

### Proxy HTTP ###

resource "aws_ecs_task_definition" "proxy-http" {
  family                   = "proxy-http"
  container_definitions    = templatefile("task/proxy-http.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
}

resource "aws_ecs_service" "proxy-http" {
  name             = "proxy-http"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.proxy-http.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.router-http.arn
    container_name   = "proxy-http"
    container_port   = 8080
  }

  network_configuration {
    subnets = [
      aws_subnet.private-a.id,
      aws_subnet.private-b.id,
      aws_subnet.private-c.id
    ]
    security_groups = [
      aws_security_group.router.id,
      aws_security_group.router-tag.id,
      aws_security_group.grpc.id,
    ]
  }
}


### Router ###

resource "aws_ecs_task_definition" "router" {
  family                   = "router"
  container_definitions    = templatefile("task/router.json", { secret = var.secret, public = var.public })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.router-execution.arn
  task_role_arn            = aws_iam_role.router-task.arn

  tags = {}
}

resource "aws_ecs_service" "router" {
  name             = "router"
  cluster          = aws_ecs_cluster.platform.id
  task_definition  = aws_ecs_task_definition.router.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_alb_target_group.router-socketio.arn
    container_name   = "proxy-socketio"
    container_port   = 3001
  }

  network_configuration {
    subnets = [
      aws_subnet.private-a.id,
      aws_subnet.private-b.id,
      aws_subnet.private-c.id
    ]
    security_groups = [
      aws_security_group.router.id,
      aws_security_group.router-tag.id,
      aws_security_group.grpc.id,
      aws_security_group.pg-outbound-from-router.id,
    ]
  }
}


#############
# Instances #
#############

data "aws_ami" "amazon-ecs-optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_security_group" "production-ecs-instance" {
  name        = "production-ecs-instance"
  description = "HTTPS outbound"
  vpc_id      =  aws_vpc.hackedu.id

  egress {
    from_port = 8888
    to_port   = 8888
    protocol  = "tcp"

    cidr_blocks = formatlist("%s/32", aws_instance.tinyproxy.*.private_ip)
  }

  ingress {
    from_port = 32768
    to_port   = 61000
    protocol  = "tcp"

    # TODO: Lock it down just to the router's security group
    cidr_blocks = [aws_vpc.hackedu.cidr_block]
  }
}
