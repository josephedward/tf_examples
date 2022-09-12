resource "aws_ses_domain_identity" "hackedu" {
  domain = var.public.ses_domain
}

resource "aws_ses_domain_dkim" "hackedu" {
  domain = aws_ses_domain_identity.hackedu.domain
}

resource "aws_route53_record" "hackedu-ses-verification" {
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = "_amazonses.${var.public.ses_domain}"
  type    = "TXT"
  ttl     = "600"

  records = [
    aws_ses_domain_identity.hackedu.verification_token,
  ]
}

resource "aws_route53_record" "hackedu-ses-dkim" {
  count   = 3
  zone_id = aws_route53_zone.hackedu-public.zone_id
  name    = "${element(aws_ses_domain_dkim.hackedu.dkim_tokens, count.index)}._domainkey.${var.public.ses_domain}"
  type    = "CNAME"
  ttl     = "600"

  records = [
    "${element(aws_ses_domain_dkim.hackedu.dkim_tokens, count.index)}.dkim.amazonses.com",
  ]
}

resource "aws_ses_email_identity" "info" {
  email = var.public.email.info
}
resource "aws_ses_email_identity" "support" {
  email = var.public.email.support
}
