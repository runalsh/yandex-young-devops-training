#====KEY ========================
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

variable "key_name" {
  type    = string
  default = "universalnew"
}

# ++++++++++++++++++++++++++++++++++++ CERTIFICATE SELFSIGNED +++++++++++++++++++++++++++++++++++++++++
#          надо бы переделать под домен на letsencrypt TODO

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cert" {
  # key_algorithm         = "RSA"
  private_key_pem       = "${tls_private_key.key.private_key_pem}"
  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["*.${var.region}.elb.amazonaws.com"]

  subject {
    common_name  = "*.${var.region}.elb.amazonaws.com"
    organization = "ORGANIZATION"
    province     = "STATE"
    country      = "COUNT"
  }
}

resource "tls_self_signed_cert" "public_cert" {
  # key_algorithm         = "RSA"
  private_key_pem       = "${tls_private_key.key.private_key_pem}"
  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["*.${var.region}.elb.amazonaws.com"]

  subject {
    common_name  = "*.${var.region}.elb.amazonaws.com"
    organization = "ORGANIZATION"
    province     = "STATE"
    country      = "COUNT"
  }
}

resource "aws_acm_certificate" "cert" {
  private_key      = "${tls_private_key.key.private_key_pem}"
  certificate_body = "${tls_self_signed_cert.public_cert.cert_pem}"
}

