# Define the Firewall rules to add to networks

# Allow bastion instance to ping BIG-IP instances, and connect to them on ports
# 22 and 443
resource "google_compute_firewall" "bastion_mgt" {
  project     = var.project_id
  name        = format("%s-allow-bastion-bigip-mgt", var.prefix)
  network     = module.management.network_self_link
  description = "Allow bastion to all BIG-IPs on management network"
  direction   = "INGRESS"
  source_service_accounts = [
    module.bastion.service_account,
  ]
  target_service_accounts = [
    local.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      22,
      443,
    ]
  }
  allow {
    protocol = "icmp"
  }
}

# Allow BIG-IP instances to connect on management network
resource "google_compute_firewall" "mgt_sync" {
  project     = var.project_id
  name        = format("%s-allow-configsync-mgt", var.prefix)
  network     = module.management.network_self_link
  description = format("ConfigSync for management network (%s)", var.prefix)
  direction   = "INGRESS"
  source_service_accounts = [
    local.bigip_sa,
  ]
  target_service_accounts = [
    local.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      443,
    ]
  }
}

# Allow BIG-IP instances to connect and sync on internal network
resource "google_compute_firewall" "int_sync" {
  project     = var.project_id
  name        = format("%s-allow-configsync-int", var.prefix)
  network     = module.internal.network_self_link
  description = format("ConfigSync for internal network (%s)", var.prefix)
  direction   = "INGRESS"
  source_service_accounts = [
    local.bigip_sa,
  ]
  target_service_accounts = [
    local.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      443,
      4353,
      "6123-6128",
    ]
  }
  allow {
    protocol = "udp"
    ports = [
      1026,
    ]
  }
}
