# Declare the three VPC networks used by this demo.

# External network - default routes to internet are removed, custom route for
# restricted API endpoints created, and private API access enabled
module "external" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "2.5.0"
  project_id                             = var.project_id
  network_name                           = format("%s-ext", var.prefix)
  description                            = format("External network for %s", var.prefix)
  delete_default_internet_gateway_routes = true
  subnets = [
    {
      subnet_name           = format("%s-ext", var.prefix)
      subnet_ip             = "172.16.0.0/16"
      subnet_region         = local.region
      subnet_private_access = true
    }
  ]
  routes = [
    {
      name              = format("%s-ext-restricted-apis", var.prefix)
      description       = format("Restricted API route (%s)", var.prefix)
      destination_range = "199.36.153.4/30"
      next_hop_internet = true
    }
  ]
}

# Management network - default routes to internet are removed, custom route for
# restricted API endpoints created, and private API access enabled
module "management" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "2.5.0"
  project_id                             = var.project_id
  network_name                           = format("%s-mgt", var.prefix)
  description                            = format("Management network for %s", var.prefix)
  delete_default_internet_gateway_routes = true
  subnets = [
    {
      subnet_name           = format("%s-mgt", var.prefix)
      subnet_ip             = "172.17.0.0/16"
      subnet_region         = local.region
      subnet_private_access = true
    }
  ]
  routes = [
    {
      name              = format("%s-mgt-restricted-apis", var.prefix)
      description       = format("Restricted API route (%s)", var.prefix)
      destination_range = "199.36.153.4/30"
      next_hop_internet = true
    }
  ]
}

# Internal - default routes to internet are removed, custom route for
# restricted API endpoints created, and private API access enabled
module "internal" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "2.5.0"
  project_id                             = var.project_id
  network_name                           = format("%s-int", var.prefix)
  description                            = format("Internal network for %s", var.prefix)
  delete_default_internet_gateway_routes = true
  subnets = [
    {
      subnet_name           = format("%s-int", var.prefix)
      subnet_ip             = "172.18.0.0/16"
      subnet_region         = local.region
      subnet_private_access = true
    }
  ]
  routes = [
    {
      name              = format("%s-int-restricted-apis", var.prefix)
      description       = format("Restricted API route (%s)", var.prefix)
      destination_range = "199.36.153.4/30"
      next_hop_internet = true
    }
  ]
}

locals {
  ext_subnet = module.external.subnets[format("%s/%s-ext", local.region, var.prefix)].self_link
  mgt_subnet = module.management.subnets[format("%s/%s-mgt", local.region, var.prefix)].self_link
  int_subnet = module.internal.subnets[format("%s/%s-int", local.region, var.prefix)].self_link
}
