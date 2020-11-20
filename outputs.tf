output "bastion_name" {
  value       = module.bastion.hostname
  description = <<EOD
The name of the bastion VM.
EOD
}

output "admin_password_key" {
  value       = module.admin_password.id
  description = <<EOD
The name of the Secret Manager key that contains the generated admin password.
EOD
}

output "bigip_addresses" {
  value       = module.cfe.instance_addresses
  description = <<EOD
The set of IPv4 addresses and CIDRs assigned to the BIG-IP instances.
EOD
}

output "cfe_label_value" {
  value       = local.cfe_label_value
  description = <<EOD
The CFE-specific label that has been applied to CFE related resources.
EOD
}
