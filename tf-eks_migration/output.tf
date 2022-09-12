output "cloudfront-root" {
  value = aws_cloudfront_distribution.root.id
}

output "cloudfront-app" {
  value = aws_cloudfront_distribution.app.id
}

output "cloudfront-www" {
  value = aws_cloudfront_distribution.www.id
}

output "vpc-id" {
  value = aws_vpc.hackedu.id
}

output "vpc-cidr" {
  value = aws_vpc.hackedu.cidr_block
}

output "public-subnet-ids" {
  value = [
    aws_subnet.public-a.id,
    aws_subnet.public-b.id,
    aws_subnet.public-c.id
  ]
}

output "private-subnet-ids" {
  value = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id,
    aws_subnet.private-c.id
  ]
}
