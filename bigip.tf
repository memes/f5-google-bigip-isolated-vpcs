# This Terraform file creates the resources that are needed for BIG-IP w/CFE
# operations:-
# 1. Custom role to allow CFE on BIG-IP to make changes to compute and storage
#    resources
# 2. Create a dedicated service account for BIG-IP, assigned the CFE role
# 3. Launch an 3-arm CFE HA cluster using the networks created in networks.tf

# Create a custom CFE role at the project
module "cfe_role" {
  source      = "git::https://github.com/memes/f5-google-terraform-modules//modules/big-ip/cfe/role?ref=1.1.0"
  target_type = "project"
  target_id   = var.project_id
  title       = format("CFE role for %s demo", var.prefix)
}

# Create a service account for BIG-IP
module "bigip_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "3.0.1"
  project_id = var.project_id
  prefix     = var.prefix
  names      = ["big-ip"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/monitoring.viewer",
    # assign the custom role
    "${var.project_id}=>${module.cfe_role.qualified_role_id}",
    # If you chose to avoid a custom role, the required permissions for CFE
    # are contained in the standard compute.instanceAdmin, compute.networkAdmin,
    # and storage.admin roles.
    #"${var.project_id}=>roles/compute.instanceAdmin",
    #"${var.project_id}=>roles/compute.networkAdmin",
    #"${var.project_id}=> roles/storage.admin",
  ]
  generate_keys = false
}

locals {
  # Break dependency on service-accounts module; BIG-IP SA email is predictable
  bigip_sa = format("%s-big-ip@%s.iam.gserviceaccount.com", var.prefix, var.project_id)
  # Simple DO to setup instances with floating self-ip
  do_payloads = [for i in range(0, 2) : templatefile("${path.module}/templates/do.json",
    {
      allow_phone_home = false,
      hostname         = format("%s-bigip-%d.%s.c.%s.internal", var.prefix, i, element(var.bigip_zones, i), var.project_id)
      ntp_servers      = ["169.254.169.254"],
      dns_servers      = ["169.254.169.254"],
      search_domains   = ["google.internal", format("%s.c.%s.internal", element(var.bigip_zones, i), var.project_id)],
      timezone         = "UTC",
      modules = {
        ltm = "nominal"
      },
    }
  )]
}

# Enable ConfigSync firewall rules between BIG-IP instances using the opinionated
# Firewall module for CFE
module "cfe_fw" {
  source                   = "git::https://github.com/memes/f5-google-terraform-modules//modules/big-ip/cfe/firewall?ref=1.1.0"
  project_id               = var.project_id
  bigip_service_account    = local.bigip_sa
  management_firewall_name = format("allow-configsync-mgt-%s", var.prefix)
  management_network       = module.management.network_self_link
  dataplane_firewall_name  = format("allow-configsync-int-%s", var.prefix)
  dataplane_network        = module.internal.network_self_link
}

# memes' BIG-IP Terraform module *requires* use of GCP Secret Manager to set
# Admin user password.

# Create a random BIG-IP password for admin and store in Secret Manager; avoid
# chars that can cause problems
module "admin_password" {
  source            = "memes/secret-manager/google//modules/random"
  version           = "0.12.2"
  project_id        = var.project_id
  id                = format("%s-bigip-admin-passwd-key", var.prefix)
  labels            = local.noncfe_resource_labels
  accessors         = formatlist("serviceAccount:%s", [local.bigip_sa])
  length            = 16
  has_special_chars = true
  min_special_chars = 1
  special_char_set  = "@#%&*()-_=+[]<>:?"
}

# Reserve IP addresses for BIG-IP on external network
module "ext_ips" {
  source     = "terraform-google-modules/address/google"
  version    = "2.1.0"
  project_id = var.project_id
  region     = local.region
  subnetwork = local.ext_subnet

  # Reserve 3 IPs; first two will be assigned to nic0 on each vm, third will be
  # a floating self-ip
  names = formatlist(format("%s-ext-%%s", var.prefix), [
    "bigip-0",
    "bigip-1",
    "vip"
  ])
}

# Reserve IP addresses for BIG-IP on management network
module "mgt_ips" {
  source     = "terraform-google-modules/address/google"
  version    = "2.1.0"
  project_id = var.project_id
  region     = local.region
  subnetwork = local.mgt_subnet

  # Reserve 2 IPs - these will be assigned to nic1
  names = formatlist(format("%s-mgt-%%s", var.prefix), [
    "bigip-0",
    "bigip-1",
  ])
}

# Reserve IP addresses for BIG-IP on internal network
module "int_ips" {
  source     = "terraform-google-modules/address/google"
  version    = "2.1.0"
  project_id = var.project_id
  region     = local.region
  subnetwork = local.int_subnet

  # Reserve 2 IPs - these will be assigned to nic2
  names = formatlist(format("%s-int-%%s", var.prefix), [
    "bigip-0",
    "bigip-1",
  ])
}

# Stand-up a 2 instance HA pair with CFE support
module "cfe" {
  source                            = "git::https://github.com/memes/f5-google-terraform-modules//modules/big-ip/cfe?ref=1.1.0"
  project_id                        = var.project_id
  instance_name_template            = format("%s-bigip-%%d", var.prefix)
  zones                             = var.bigip_zones
  machine_type                      = "n1-standard-8"
  service_account                   = local.bigip_sa
  external_subnetwork               = local.ext_subnet
  external_subnetwork_network_ips   = slice(module.ext_ips.addresses, 0, 2)
  external_subnetwork_vip_cidrs     = [element(module.ext_ips.addresses, 2)]
  provision_external_public_ip      = false
  management_subnetwork             = local.mgt_subnet
  management_subnetwork_network_ips = module.mgt_ips.addresses
  provision_management_public_ip    = false
  internal_subnetworks              = [local.int_subnet]
  internal_subnetwork_network_ips   = [for a in module.int_ips.addresses : [a]]
  provision_internal_public_ip      = false
  image                             = var.image
  admin_password_secret_manager_key = module.admin_password.secret_id
  labels                            = var.labels
  cfe_label_key                     = var.cfe_label_key
  cfe_label_value                   = local.cfe_label_value
  install_cloud_libs                = var.install_cloud_libs
}
