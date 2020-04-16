

resource "aws_route53_record" "vault_lb" {
  zone_id = var.zone_id
   name    = "vault.${var.namespace}"
  type    = "CNAME"
  records = [aws_alb.vault.dns_name]
  ttl     = "300"
}


