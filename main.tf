

resource "random_password" "vault_admin_password" {
  length = 16
  special = true
  override_special = "_%@"
}


//--------------------------------------------------------------------
// Vault KMS Keys for auto-unseal
resource "aws_kms_key" "vaultkms" {
  description             = "KMS for Vault Raft demo"
  deletion_window_in_days = 10

  tags = {
    Name           = "${var.namespace}-kms"
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

//--------------------------------------------------------------------
// Vault Server Leader Instance

resource "aws_instance" "vault-server-leader" {

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.vault_subnet[0].id
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.vault_sg.id]
  associate_public_ip_address = true
  private_ip                  = var.vault_leader_private_ips
  iam_instance_profile        = aws_iam_instance_profile.vault-server.id

  # user_data = data.template_file.vault-server[count.index].rendered
  user_data = templatefile("${path.module}/templates/userdata-vault-leader.tpl", {
    tpl_vault_node_name = var.vault_leader_names,
    tpl_vault_storage_path = "/vault/${var.vault_leader_names}",
    tpl_vault_zip_file = var.vault_zip_file,
    tpl_vault_service_name = "vault-${var.namespace}",
    cert = tls_locally_signed_cert.vault.cert_pem,
    key  = tls_private_key.vault.private_key_pem,
    kmskey        = aws_kms_key.vaultkms.id,
    region = var.region,
    vault_ent_license = var.vault_ent_license,
    vault_admin = var.vault_admin,
    vault_admin_password = random_password.vault_admin_password.result
  })

  tags = {
    Name = "${var.namespace}-vault-leader"
  }

  lifecycle {
    ignore_changes = [ami, tags]
  }
}

//--------------------------------------------------------------------
// Vault Server Leader Instance

resource "aws_instance" "vault-server-follower" {
  count                       = length(var.vault_follower_names)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.vault_subnet[0].id
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.vault_sg.id]
  associate_public_ip_address = true
  private_ip                  = var.vault_follower_private_ips[count.index]
  iam_instance_profile        = aws_iam_instance_profile.vault-server.id

  # user_data = data.template_file.vault-server[count.index].rendered
  user_data = templatefile("${path.module}/templates/userdata-vault-follower.tpl", {
    tpl_vault_node_name = var.vault_follower_names[count.index],
    tpl_vault_storage_path = "/vault/${var.vault_follower_names[count.index]}",
    tpl_vault_zip_file = var.vault_zip_file,
    tpl_vault_service_name = "vault-${var.namespace}",
    tpl_vault_leader_addr = "https://${aws_route53_record.vault_lb.fqdn}:8200",
    cert = element(tls_locally_signed_cert.vault.*.cert_pem, count.index),
    key  = element(tls_private_key.vault.*.private_key_pem, count.index),
    kmskey        = aws_kms_key.vaultkms.id,
    region = var.region,
    vault_ent_license = var.vault_ent_license
  })

  tags = {
    Name = "${var.namespace}-vault-follower-${var.vault_follower_names[count.index]}"
  }

  lifecycle {
    ignore_changes = [ami, tags]
  }

  depends_on = [
    aws_instance.vault-server-leader,
  ]
}

## Vault Server IAM Config
resource "aws_iam_instance_profile" "vault-server" {
  name = "${var.namespace}-vault-server-instance-profile"
  role = aws_iam_role.vault-server.name
}

resource "aws_iam_role" "vault-server" {
  name               = "${var.namespace}-vault-server-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault-server" {
  name   = "${var.namespace}-vault-server-role-policy"
  role   = aws_iam_role.vault-server.id
  policy = data.aws_iam_policy_document.vault-server.json
}



//--------------------------------------------------------------------
// Data Sources

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-server" {
  statement {
    sid    = "1"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }

  statement {
    sid    = "VaultAWSAuthMethod"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }
}
