#############
#   zones   #
#############

resource "aws_route53_zone" "hackedu-public" {
  name = var.public.urls.root
}

resource "aws_route53_zone" "hackedu-private" {
  name = var.public.urls.root

  vpc {
    vpc_id = aws_vpc.hackedu.id
  }
}


##################
#   mx records   #
##################

resource "aws_route53_record" "hackedu-mx" {
  zone_id = aws_route53_zone.hackedu-public.id
  name    = var.public.urls.root
  type    = "MX"
  ttl     = "300"
  records = [
    "1 ASPMX.L.GOOGLE.COM.",
    "5 ALT1.ASPMX.L.GOOGLE.COM.",
    "5 ALT2.ASPMX.L.GOOGLE.COM.",
    "10 ASPMX2.GOOGLEMAIL.COM.",
    "10 ASPMX3.GOOGLEMAIL.COM."
  ]
}


###################
#   txt records   #
###################

resource "aws_route53_record" "hackedu-txt" {
  zone_id = aws_route53_zone.hackedu-public.id
  name    = var.public.urls.root
  type    = "TXT"
  ttl     = "300"
  records = [
    "google-site-verification=${var.public.dns.google-site-verification}"
  ]
}


#####################
#   other records   #
#####################

resource "aws_route53_record" "sandbox" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = "*.${var.public.urls.sandbox}"
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_alb.router.dns_name ]
}

resource "aws_route53_record" "sandbox-private" {
  zone_id = aws_route53_zone.hackedu-private.zone_id
  name    = "*.${var.public.urls.sandbox}"
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_alb.router.dns_name ]
}

resource "aws_route53_record" "control" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = var.public.urls.control
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_alb.router.dns_name ]
}

resource "aws_route53_record" "control-private" {
  zone_id = aws_route53_zone.hackedu-private.id
  name    = var.public.private_urls.control
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_alb.router.dns_name ]
}

# TODO: Rename db to match prod
resource "aws_route53_record" "production-db" {
  zone_id = aws_route53_zone.hackedu-private.id
  name    = var.public.private_urls.db
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_db_instance.platform.address ]
}

resource "aws_route53_record" "platform-private" {
  zone_id = aws_route53_zone.hackedu-private.id
  name    = var.public.private_urls.platform
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_alb.platform.dns_name ]
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = var.public.urls.root
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.root.domain_name
    zone_id                = aws_cloudfront_distribution.root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = var.public.urls.app
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app.domain_name
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = var.public.urls.www
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www.domain_name
    zone_id                = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}
