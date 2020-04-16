output "a_Welcome_Message" {
  value = <<SHELLCOMMANDS


░░░░░░░█▐▓▓░████▄▄▄█▀▄▓▓▓▌█ much secrets
░░░░░▄█▌▀▄▓▓▄▄▄▄▀▀▀▄▓▓▓▓▓▌█
░░░▄█▀▀▄▓█▓▓▓▓▓▓▓▓▓▓▓▓▀░▓▌█
░░█▀▄▓▓▓███▓▓▓███▓▓▓▄░░▄▓▐█▌ very HA
░█▌▓▓▓▀▀▓▓▓▓███▓▓▓▓▓▓▓▄▀▓▓▐█
▐█▐██▐░▄▓▓▓▓▓▀▄░▀▓▓▓▓▓▓▓▓▓▌█▌
█▌███▓▓▓▓▓▓▓▓▐░░▄▓▓███▓▓▓▄▀▐█ such secure
█▐█▓▀░░▀▓▓▓▓▓▓▓▓▓██████▓▓▓▓▐█
▌▓▄▌▀░▀░▐▀█▄▓▓██████████▓▓▓▌█▌
▌▓▓▓▄▄▀▀▓▓▓▀▓▓▓▓▓▓▓▓█▓█▓█▓▓▌█▌ Wow.
█▐▓▓▓▓▓▓▄▄▄▓▓▓▓▓▓█▓█▓█▓█▓▓▓▐█


SHELLCOMMANDS
}

output "endpoints" {
  value = <<EOF

  vault_transit (${aws_instance.vault-transit.public_ip}) | internal: (${aws_instance.vault-transit.private_ip})
    - Initialized and unsealed.
    - The root token creates a transit key that enables the other Vaults to auto-unseal.
    - Does not join the High-Availability (HA) cluster.

  vault_leader (${aws_instance.vault-server-leader.public_ip}) | internal: (${aws_instance.vault-server-leader.private_ip})
    - Initialized and unsealed.
    - The root token and recovery key is stored in /tmp/key.json.
    - K/V-V2 secret engine enabled and secret stored.
    - Leader of HA cluster
    $ ssh -l ubuntu ${aws_instance.vault-server-leader.public_ip} -i ${var.ssh_public_key}
    # Root token:
    $ ssh -l ubuntu ${aws_instance.vault-server-leader.public_ip} -i ${var.ssh_public_key} "cat ~/root_token"
    # Recovery key:
    $ ssh -l ubuntu ${aws_instance.vault-server-leader.public_ip} -i ${var.ssh_public_key} "cat ~/recovery_key"

  vault_3 (${aws_instance.vault-server-follower[0].public_ip}) | internal: (${aws_instance.vault-server-follower[0].private_ip})
    - Started
    $ ssh -l ubuntu ${aws_instance.vault-server-follower[0].public_ip} -i ${var.ssh_public_key}

  vault_4 (${aws_instance.vault-server-follower[1].public_ip}) | internal: (${aws_instance.vault-server-follower[1].private_ip})
    - Started
    $ ssh -l ubuntu ${aws_instance.vault-server-follower[1].public_ip} -i ${var.ssh_public_key}

  Vault LB for GUI HTTPS:
  https://${aws_route53_record.vault_lb.fqdn}:8200


EOF
}