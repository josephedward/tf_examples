# Subnets
resource "aws_elasticache_subnet_group" "production" {
  name       = "production-subnet"
  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id,
    aws_subnet.private-c.id
  ]
}

# TODO: Update production parameter_group_name
resource "aws_elasticache_cluster" "test-engine" {
  cluster_id           = "test-engine"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.production.id

  security_group_ids = [
      aws_security_group.router.id,
      aws_security_group.router-tag.id,
      aws_security_group_rule.flask-api-ingress-from-public.id,
      aws_security_group.elasticache-internal.id,
  ]
}
