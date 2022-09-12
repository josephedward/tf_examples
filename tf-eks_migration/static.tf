resource "aws_instance" "static" {
  ami                         = "ami-09d95fab7fff3776c"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.bastion.key_name
  associate_public_ip_address = true

  tags = {
    Name = "static"
  }

  subnet_id = aws_subnet.public-a.id

  vpc_security_group_ids = [
    aws_security_group.trusted-ssh.id,
    aws_security_group.http-ingress.id,
    aws_security_group.http-egress.id
  ]

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "static" {
  instance = aws_instance.static.id
  vpc      = true
}

resource "aws_security_group" "trusted-ssh" {
  name        = "trusted-ssh"
  description = "ssh access from trusted cidr block"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = var.public.trusted_cidr_block
  }
}

resource "aws_security_group" "http-ingress" {
  name        = "http-ingress"
  description = "http ingress"
  vpc_id      = aws_vpc.hackedu.id


  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "http-egress" {
  name        = "http-egress"
  description = "http egress"
  vpc_id      = aws_vpc.hackedu.id


  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "static-egress" {
  name        = "static-egress"
  description = "static egress"
  vpc_id      = aws_vpc.hackedu.id


  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "${aws_eip.static.public_ip}/32"
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${aws_eip.static.public_ip}/32"
    ]
  }
}

resource "aws_route53_record" "static" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = var.public.urls.static
  type    = "A"
  ttl     = "300"
  records = [
    aws_eip.static.public_ip,
  ]
}

resource "aws_route53_record" "static-private" {
  zone_id = aws_route53_zone.hackedu-private.zone_id
  name    = var.public.urls.static
  type    = "A"
  ttl     = "300"
  records = [
    aws_eip.static.public_ip,
  ]
}
