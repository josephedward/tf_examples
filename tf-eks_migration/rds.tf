# Subnets
resource "aws_db_subnet_group" "production" {
  name       = "production subnet"
  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id,
    aws_subnet.private-c.id
  ]
}

resource "aws_db_subnet_group" "production-public" {
  name       = "production subnet - public"
  subnet_ids = [
    aws_subnet.public-a.id,
    aws_subnet.public-b.id,
    aws_subnet.public-c.id
  ]
}

# Security groups
resource "aws_security_group" "pg-inbound-from-bastion" {
  depends_on  = [aws_instance.bastion]
  name        = "pg-inbound-from-bastion"
  description = "DB access via the bastion host"
  vpc_id      = aws_vpc.hackedu.id
  ingress {
    from_port = 5432
    protocol  = "tcp"
    to_port   = 5432

    cidr_blocks = [
      "${aws_instance.bastion.private_ip}/32",
    ]
  }
}

# RDS for all apis
resource "aws_security_group" "tag-api" {
  name        = "tag-api"
  description = "Tag for api"
  vpc_id      = aws_vpc.hackedu.id
}

resource "aws_security_group" "pg-outbound-from-api" {
  name        = "pg-outbound-from-api"
  description = "Outbound posgres from all apis"
  vpc_id      = aws_vpc.hackedu.id

  egress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.tag-api.id]
  }
}

resource "aws_security_group" "pg-inbound-from-api" {
  name        = "pg-inbound-from-api"
  description = "DB access from api"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.tag-api.id]
  }
}

# RDS for router
resource "aws_security_group" "pg-outbound-from-router" {
  name        = "pg-outbound-from-router"
  description = "Outbound Postgres from router"
  vpc_id      = aws_vpc.hackedu.id

  egress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.router-tag.id]
  }
}

resource "aws_security_group" "pg-inbound-from-router" {
  name        = "pg-inbound-from-router"
  description = "Inbound Postgres from router"
  vpc_id      = aws_vpc.hackedu.id

  ingress {
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.router-tag.id]
  }
}

# RDS for Platform
resource "aws_db_instance" "platform" {
  depends_on              = [aws_instance.bastion]
  allocated_storage       = 100
  storage_type            = "gp2"
  engine                  = "postgres"
  identifier              = "platform"
  instance_class          = "db.t3.small"
  name                    = "platform"
  username                = var.secret.db-platform.user
  password                = var.secret.db-platform.pass
  db_subnet_group_name    = aws_db_subnet_group.production.id
  multi_az                = false
  storage_encrypted       = true
  copy_tags_to_snapshot   = true

  backup_retention_period = 7
  skip_final_snapshot     = true
  backup_window           = "02:00-04:00"

  vpc_security_group_ids = [
    aws_security_group.pg-inbound-from-bastion.id,
    aws_security_group.tag-api.id,
    aws_security_group.pg-inbound-from-api.id,
    aws_security_group.router-tag.id,
    aws_security_group.pg-inbound-from-router.id,
  ]
}
