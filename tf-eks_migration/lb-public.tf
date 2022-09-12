resource "aws_ecr_repository" "api-public" {
  name = "api-public"
}

# Security groups
resource "aws_security_group" "public" {
  name        = "public"
  description = "public"
  vpc_id      = aws_vpc.hackedu.id
}

resource "aws_security_group_rule" "public-ingress-on-80-from-alb" {
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public.id
  to_port                  = 80
  type                     = "ingress"
  source_security_group_id = aws_security_group.public-alb.id
}

resource "aws_security_group_rule" "public-ingress-on-5000-from-alb" {
  from_port                = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public.id
  to_port                  = 5000
  type                     = "ingress"
  source_security_group_id = aws_security_group.public-alb.id
}

resource "aws_security_group_rule" "public-egress-to-all" {
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public.id
  to_port                  = 65535
  type                     = "egress"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group" "public-alb" {
  name        = "public-alb"
  description = "public-alb"
  vpc_id      = aws_vpc.hackedu.id
}

resource "aws_security_group_rule" "public-alb-ingress-from-internet" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.public-alb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public-alb-egress-to-80" {
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public-alb.id
  to_port                  = 80
  type                     = "egress"
  source_security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public-alb-egress-to-5000" {
  from_port                = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public-alb.id
  to_port                  = 5000
  type                     = "egress"
  source_security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public-alb-egress-to-6000" {
  from_port                = 6000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public-alb.id
  to_port                  = 6000
  type                     = "egress"
  source_security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "flask-api-ingress-from-public" {
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group_rule.flask-api-ingress-from-public.id
  to_port                  = 80
  type                     = "ingress"
  source_security_group_id = aws_security_group.public.id
}

# Load balancer
resource "aws_alb" "public" {
  name                       = "public"
  internal                   = false
  subnets                    = [
    aws_subnet.public-a.id,
    aws_subnet.public-b.id,
    aws_subnet.public-c.id
  ]
  security_groups            = [aws_security_group.public-alb.id]
  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_alb_listener" "public" {
  load_balancer_arn = aws_alb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  #certificate_arn   = aws_acm_certificate.api.arn
  certificate_arn   = aws_acm_certificate.platform.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\": \"not found\"}"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_certificate" "public-api" {
  listener_arn    = aws_alb_listener.public.arn
  certificate_arn = aws_acm_certificate.api.arn
}