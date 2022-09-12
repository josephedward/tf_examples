resource "aws_vpc" "hackedu" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "hackedu"
  }
}

resource "aws_internet_gateway" "primary" {
  vpc_id = aws_vpc.hackedu.id

  tags = {
    Name = "development-igw"
  }
}

resource "aws_eip" "nat-a" {
  vpc = true
}

resource "aws_eip" "nat-b" {
  vpc = true
}

resource "aws_eip" "nat-c" {
  vpc = true
}

resource "aws_nat_gateway" "nat-a" {
  allocation_id = aws_eip.nat-a.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "development-nat-a"
  }

  depends_on = [
    aws_internet_gateway.primary
  ]
}

resource "aws_nat_gateway" "nat-b" {
  allocation_id = aws_eip.nat-b.id
  subnet_id     = aws_subnet.public-b.id

  tags = {
    Name = "development-nat-b"
  }

  depends_on = [
    aws_internet_gateway.primary
  ]
}

resource "aws_nat_gateway" "nat-c" {
  allocation_id = aws_eip.nat-c.id
  subnet_id     = aws_subnet.public-c.id

  tags = {
    Name = "development-nat-c"
  }

  depends_on = [
    aws_internet_gateway.primary
  ]
}

resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.hackedu.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "development-public-a"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id            = aws_vpc.hackedu.id
  cidr_block        = "10.0.32.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "development-public-b"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id            = aws_vpc.hackedu.id
  cidr_block        = "10.0.48.0/20"
  availability_zone = "us-east-1c"

  tags = {
    Name = "development-public-c"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.hackedu.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "development-private-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.hackedu.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "development-private-b"
  }
}

resource "aws_subnet" "private-c" {
  vpc_id            = aws_vpc.hackedu.id
  cidr_block        = "10.0.160.0/20"
  availability_zone = "us-east-1c"

  tags = {
    Name = "development-private-c"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hackedu.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private-a" {
  vpc_id = aws_vpc.hackedu.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-a.id
  }

  tags = {
    Name = "private-a"
  }
}

resource "aws_route_table" "private-b" {
  vpc_id = aws_vpc.hackedu.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-b.id
  }

  tags = {
    Name = "private-b"
  }
}

resource "aws_route_table" "private-c" {
  vpc_id = aws_vpc.hackedu.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-c.id
  }

  tags = {
    Name = "private-c"
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-c" {
  subnet_id      = aws_subnet.public-c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private-a.id
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_route_table.private-b.id
}

resource "aws_route_table_association" "private-c" {
  subnet_id      = aws_subnet.private-c.id
  route_table_id = aws_route_table.private-c.id
}
