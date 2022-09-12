data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "tinyproxy" {
  count = var.public.tinyproxy.count

  ami                         = "ami-927185ef"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.general.key_name
  associate_public_ip_address = false

  tags = {
    Name = "tinyproxy-${count.index}"
  }

  subnet_id = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id,
    aws_subnet.private-c.id
  ][count.index]
  vpc_security_group_ids = [
    aws_security_group.ssh-internal.id,
    aws_security_group.tinyproxy-outbound.id,
    aws_security_group.tinyproxy-http.id
  ]

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_security_group" "tinyproxy-outbound" {
  name        = "tinyproxy-outbound"
  description = "outbound access for tinyproxy"
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

  ingress {
    from_port = 8888
    to_port   = 8888
    protocol  = "tcp"

    cidr_blocks = [
      aws_vpc.hackedu.cidr_block
    ]
  }
}

resource "aws_security_group" "tinyproxy-http" {
  name        = "tinyproxy-http"
  description = "http access for tinyproxy"
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

resource "aws_route53_record" "tinyproxy" {
  zone_id = aws_route53_zone.hackedu-private.zone_id
  name    = var.public.private_urls.tinyproxy
  type    = "A"
  ttl     = "300"
  records = [
    element(aws_instance.tinyproxy.*.private_ip, 0),
    element(aws_instance.tinyproxy.*.private_ip, 1)
  ]
}
