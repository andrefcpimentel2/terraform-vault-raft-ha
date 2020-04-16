

# Client private key

resource "tls_private_key" "vault" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_self_signed_cert" "vault" {
  key_algorithm   = tls_private_key.vault.algorithm
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name  = "vault.${var.namespace}.${data.aws_route53_zone.fdqn.name}"
    organization = "HashiCorp"
  }

  validity_period_hours = 720

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]
}

# Client signing request
resource "tls_cert_request" "vault" {
  key_algorithm   = tls_private_key.vault.algorithm
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name  = "vault.${var.namespace}.${data.aws_route53_zone.fdqn.name}"
    organization = "HashiCorp"
  }

  dns_names = [
    # vault
    "vault.${var.namespace}.${data.aws_route53_zone.fdqn.name}",
    # Common
    "localhost",
    "*.${var.namespace}.${data.aws_route53_zone.fdqn.name}",
  ]

}

# Client certificate

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem = tls_cert_request.vault.cert_request_pem

  ca_key_algorithm = var.ca_key_algorithm
  ca_private_key_pem = tls_private_key.vault.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vault.cert_pem

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]
}





# Client private key

resource "tls_private_key" "followers" {
  count       = length(var.vault_follower_names)
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

# Client signing request
resource "tls_cert_request" "followers" {
  count           = length(var.vault_follower_names)
  key_algorithm   = element(tls_private_key.followers.*.algorithm, count.index)
  private_key_pem = element(tls_private_key.followers.*.private_key_pem, count.index)

  subject {
    common_name  = "vault.follower${count.index}.${var.namespace}.${data.aws_route53_zone.fdqn.name}"
    organization = "HashiCorp"
  }

  dns_names = [
    # Vault
    "vault.follower${count.index}.${var.namespace}.${data.aws_route53_zone.fdqn.name}",
    
    # Common
    "localhost",
    "*.${var.namespace}.${data.aws_route53_zone.fdqn.name}",
  ]
}

# Client certificate

resource "tls_self_signed_cert" "followers" {
  count           = length(var.vault_follower_names)
  key_algorithm   = element(tls_private_key.followers.*.algorithm, count.index)
  private_key_pem = element(tls_private_key.followers.*.private_key_pem, count.index)

  subject {
    common_name  = "vault.follower${count.index}.${var.namespace}.${data.aws_route53_zone.fdqn.name}"
    organization = "HashiCorp"
  }

  validity_period_hours = 720

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]
}

resource "tls_locally_signed_cert" "followers" {
  count            = length(var.vault_follower_names)
  cert_request_pem = element(tls_cert_request.followers.*.cert_request_pem, count.index)

  ca_key_algorithm = element(tls_private_key.followers.*.algorithm, count.index)
  ca_private_key_pem = element(tls_private_key.followers.*.private_key_pem, count.index)
  ca_cert_pem        = element(tls_self_signed_cert.followers.*.cert_pem, count.index)

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]
}


// ALB certs
resource "aws_acm_certificate" "cert" {
   domain_name       = "*.${var.namespace}.${data.aws_route53_zone.fdqn.name}"
  validation_method = "DNS"

  tags = {
    Name           = "${var.namespace}-vault"
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation_record" {
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = var.zone_id
  records = [ aws_acm_certificate.cert.domain_validation_options.0.resource_record_value ]
  ttl     = "60"
  allow_overwrite = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [
    aws_route53_record.validation_record.fqdn,
  ]
}
