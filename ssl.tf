data "aws_secretsmanager_secret" "cloudflare_api_key" {
  name = var.cloudflare_secret_name

  tags = local.tags
}

data "aws_secretsmanager_secret_version" "cloudflare_api_key" {
  secret_id = data.aws_secretsmanager_secret.cloudflare_api_key.id
}

resource "aws_acm_certificate" "this" {
  domain_name               = "*.${var.cloudflare_zone_name}"
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "validation" {
  zone_id = data.cloudflare_zone.this.id
  name    = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_type
  value   = replace(tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value, "/.$/", "")
  ttl     = 60
  proxied = false

  allow_overwrite = true

  depends_on = [aws_acm_certificate.this]
}


resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = cloudflare_record.validation.*.hostname
}

data "aws_lb" "monitoring" {
  name = "monitoring-stack-alb"
  depends_on = [ module.eks_blueprints_addons ]
}

resource "cloudflare_record" "grafana" {
  zone_id = data.cloudflare_zone.this.id
  name    = "${var.environament}-grafana"
  type    = "CNAME"
  value   = data.aws_lb.monitoring.dns_name
  ttl     = 60
  proxied = false

  allow_overwrite = true

  depends_on = [aws_acm_certificate.this]
}

resource "cloudflare_record" "prometheus" {
  zone_id = data.cloudflare_zone.this.id
  name    = "${var.environament}-prometheus"
  type    = "CNAME"
  value   = data.aws_lb.monitoring.dns_name
  ttl     = 60
  proxied = false

  allow_overwrite = true

  depends_on = [aws_acm_certificate.this]
}

resource "cloudflare_record" "alertmanager" {
  zone_id = data.cloudflare_zone.this.id
  name    = "${var.environament}-alertmanager"
  type    = "CNAME"
  value   = data.aws_lb.monitoring.dns_name
  ttl     = 60
  proxied = false

  allow_overwrite = true

  depends_on = [aws_acm_certificate.this]
}