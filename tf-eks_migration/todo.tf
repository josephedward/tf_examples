resource "aws_route53_record" "auth" {
  zone_id = aws_route53_zone.hackedu-public.id
  name    = var.public.urls.auth
  type    = "CNAME"
  ttl     = "300"

  # TODO: Reference the terraform object here instead of hardcoded variable
  records = ["d1c2jtmd3o2bu5.cloudfront.net"]
}
