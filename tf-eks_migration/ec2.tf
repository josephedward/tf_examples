resource "aws_key_pair" "bastion" {
  key_name   = "bastion"
  public_key = file("key/bastion")
}

resource "aws_key_pair" "general" {
  key_name   = "general"
  public_key = file("key/general")
}

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "ssh only"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh-internal" {
  name        = "ssh-internal"
  description = "ssh only from the vpc"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [aws_vpc.hackedu.cidr_block]
  }
}

resource "aws_security_group" "elasticache-internal" {
  name        = "elasticache-internal"
  description = "connect to elasticache only from the vpc"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"

    cidr_blocks = [aws_vpc.hackedu.cidr_block]
  }
  egress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"

    cidr_blocks = [aws_vpc.hackedu.cidr_block]
  }
}

resource "aws_security_group" "vpc-full" {
  name        = "vpc-full"
  description = "full outbound access within the vpc"
  vpc_id      = aws_vpc.hackedu.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      aws_vpc.hackedu.cidr_block
    ]
  }
}

resource "aws_security_group" "grpc" {
  name        = "grpc"
  description = "group that allows grpc to members"
  vpc_id      = aws_vpc.hackedu.id
}

resource "aws_security_group_rule" "grpc-ingress" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.grpc.id
  source_security_group_id = aws_security_group.grpc.id
}

resource "aws_security_group_rule" "grpc-egress" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.grpc.id
  source_security_group_id = aws_security_group.grpc.id
}

resource "aws_security_group" "router-tag" {
  name        = "router-tag"
  description = "empty security group to break security group cycle in terraform"
  vpc_id      = aws_vpc.hackedu.id
}

resource "aws_security_group" "router-elb" {
  name        = "router-elb"
  description = "router elb access"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 3001
    to_port   = 3001
    protocol  = "TCP"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 8080
    to_port   = 8080
    protocol  = "TCP"

    security_groups = [
      aws_security_group.router-tag.id
    ]
  }

  egress {
    from_port = 3001
    to_port   = 3001
    protocol  = "TCP"

    security_groups = [
      aws_security_group.router-tag.id
    ]
  }
}

resource "aws_security_group" "internal" {
  name = "internal"
  description = "internal access"
  vpc_id = aws_vpc.hackedu.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"

    security_groups = [
      aws_security_group_rule.flask-api-ingress-from-public.id
    ]
  }

  egress {
    from_port = 5000
    to_port   = 5000
    protocol  = "TCP"

//       aws_security_group_rule.flask-api-ingress-from-public.id
    security_groups = [

            aws_security_group_rule.flask-api-ingress-from-public.id
    ]
  }
}

resource "aws_security_group" "router" {
  name = "router"
  description = "router access"
  vpc_id = aws_vpc.hackedu.id

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "TCP"

    security_groups = [ aws_security_group.router-elb.id ]
  }

  ingress {
    from_port = 3001
    to_port   = 3001
    protocol  = "TCP"

    security_groups = [ aws_security_group.router-elb.id ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 32768
    to_port   = 61000
    protocol  = "TCP"

    // TODO: Lock this down to just sandboxes
    cidr_blocks = [
      aws_vpc.hackedu.cidr_block
    ]
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-55ef662f" # Amazon Linux 2017.09.1
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.bastion.key_name
  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }

  subnet_id              = aws_subnet.public-a.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.vpc-full.id
  ]
}

resource "aws_alb" "router" {
  name                       = "production-router-alb"
  internal                   = false
  subnets                    = [
    aws_subnet.public-a.id,
    aws_subnet.public-b.id,
    aws_subnet.public-c.id
  ]
  security_groups            = [ aws_security_group.router-elb.id ]
  enable_deletion_protection = true

  access_logs {
    bucket        = aws_s3_bucket.access-logs.id
    prefix        = "production-router-alb"
    enabled       = true
  }

  tags = {
    Environment = var.public.environment
  }
}

resource "aws_alb_target_group" "router-socketio" {
  name        = "router-socketio"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  stickiness {
    type    = "lb_cookie"
    enabled = true
  }

  health_check {
    interval = 5
    timeout  = 3
    path     = "/health"
    matcher  = "200"
  }
}

resource "aws_alb_target_group" "router-http" {
  name        = "router-http"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hackedu.id
  target_type = "ip"

  health_check {
    interval = 5
    timeout  = 3
    path     = "/health"
    matcher  = "200"
  }
}

resource "aws_alb_listener_rule" "control" {
  listener_arn = aws_alb_listener.router-http.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.router-socketio.arn
  }

  condition {
    host_header {
      values = [var.public.urls.control]
    }
  }
}

resource "aws_alb_listener_rule" "sandbox" {
  listener_arn = aws_alb_listener.router-http.arn
  priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.router-http.arn
  }

  condition {
    host_header {
      values = [var.public.urls.sandbox]
    }
  }
}

resource "aws_alb_listener" "router-http" {
  load_balancer_arn = aws_alb.router.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.sandbox.arn

  default_action {
    target_group_arn = aws_alb_target_group.router-http.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "router-http-control" {
  listener_arn    = aws_alb_listener.router-http.arn
  certificate_arn = aws_acm_certificate.control.arn
}
