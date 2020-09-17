# Setup a private Cloud DNS zone to override googleapis.com with
# restricted.googleapis.com.
module "googleapis" {
  source      = "terraform-google-modules/cloud-dns/google"
  version     = "3.0.2"
  project_id  = var.project_id
  type        = "private"
  name        = "restricted-googleapis-com"
  domain      = "googleapis.com."
  description = "Override googleapis.com domain to use restricted.googleapis.com"
  # Apply to all three networks
  private_visibility_config_networks = [
    module.external.network_self_link,
    module.management.network_self_link,
    module.internal.network_self_link,
  ]
  recordsets = [
    {
      name = "*"
      type = "CNAME"
      ttl  = 300
      records = [
        "restricted.googleapis.com.",
      ]
    },
    {
      name = "restricted"
      type = "A"
      ttl  = 300
      records = [
        "199.36.153.4",
        "199.36.153.5",
        "199.36.153.6",
        "199.36.153.7",
      ]
    }
  ]
}
