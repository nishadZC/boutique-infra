data "aws_route53_zone" "base_domain" {
  name = var.base_domain
}

# Route 53 dns record for vpn
resource "aws_route53_record" "bastion_host_record" {
  zone_id = data.aws_route53_zone.base_domain.id
  name    = "bastion.${var.environment}.${var.base_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.bastion_host.public_ip]
}

# ACM domain certificate for environment + base.domain
resource "aws_acm_certificate" "eks_domain_cert" {
  domain_name               = "${var.environment}.${var.base_domain}"
  subject_alternative_names = ["*.${var.environment}.${var.base_domain}"]
  validation_method         = "DNS"

  tags = {
    Name = "${var.environment}.${var.base_domain}"
  }
}

# dns record validation for base_domain
resource "aws_route53_record" "eks_domain_cert_validation_dns" {
  for_each = {
    for dvo in aws_acm_certificate.eks_domain_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.base_domain.zone_id
}

# SSL/TLS certificate validation for base_domain
resource "aws_acm_certificate_validation" "eks_domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.eks_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.eks_domain_cert_validation_dns : record.fqdn]
}
