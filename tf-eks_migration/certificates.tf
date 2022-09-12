############
#   root   #
############

resource "aws_acm_certificate" "root" {
  domain_name       = var.public.urls.root
  validation_method = "DNS"
}

resource "aws_route53_record" "root-validation" {
  for_each = {
    for dvo in aws_acm_certificate.root.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "root-validation" {
  certificate_arn         = aws_acm_certificate.root.arn
  validation_record_fqdns = [for record in aws_route53_record.root-validation : record.fqdn]
}


###########
#   api   #
###########

resource "aws_acm_certificate" "api" {
  domain_name       = var.public.urls.api
  validation_method = "DNS"
}

resource "aws_route53_record" "api-validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "api-validation" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.api-validation : record.fqdn]
}


###########
#   app   #
###########

resource "aws_acm_certificate" "app" {
  domain_name       = var.public.urls.app
  validation_method = "DNS"
}

resource "aws_route53_record" "app-validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "app-validation" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for record in aws_route53_record.app-validation : record.fqdn]
}


############
#   auth   #
############

resource "aws_acm_certificate" "auth" {
  domain_name       = var.public.urls.auth
  validation_method = "DNS"
}

resource "aws_route53_record" "auth-validation" {
  for_each = {
    for dvo in aws_acm_certificate.auth.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "auth-validation" {
  certificate_arn         = aws_acm_certificate.auth.arn
  validation_record_fqdns = [for record in aws_route53_record.auth-validation : record.fqdn]
}


###############
#   control   #
###############

resource "aws_acm_certificate" "control" {
  domain_name       = var.public.urls.control
  validation_method = "DNS"
}

resource "aws_route53_record" "control-validation" {
  for_each = {
    for dvo in aws_acm_certificate.control.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "control-validation" {
  certificate_arn         = aws_acm_certificate.control.arn
  validation_record_fqdns = [for record in aws_route53_record.control-validation : record.fqdn]
}


################
#   platform   #
################

resource "aws_acm_certificate" "platform" {
  domain_name       = var.public.urls.platform
  validation_method = "DNS"
}

resource "aws_route53_record" "platform-validation" {
  for_each = {
    for dvo in aws_acm_certificate.platform.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "platform-validation" {
  certificate_arn         = aws_acm_certificate.platform.arn
  validation_record_fqdns = [for record in aws_route53_record.platform-validation : record.fqdn]
}


###############
#   sandbox   #
###############

resource "aws_acm_certificate" "sandbox" {
  domain_name       = "*.${var.public.urls.sandbox}"
  validation_method = "DNS"
}

resource "aws_route53_record" "sandbox-validation" {
  for_each = {
    for dvo in aws_acm_certificate.sandbox.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "sandbox-validation" {
  certificate_arn         = aws_acm_certificate.sandbox.arn
  validation_record_fqdns = [for record in aws_route53_record.sandbox-validation : record.fqdn]
}


###########
#   www   #
###########

resource "aws_acm_certificate" "www" {
  domain_name       = var.public.urls.www
  validation_method = "DNS"
}

resource "aws_route53_record" "www-validation" {
  for_each = {
    for dvo in aws_acm_certificate.www.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hackedu-public.zone_id
}

resource "aws_acm_certificate_validation" "www-validation" {
  certificate_arn         = aws_acm_certificate.www.arn
  validation_record_fqdns = [for record in aws_route53_record.www-validation : record.fqdn]
}
