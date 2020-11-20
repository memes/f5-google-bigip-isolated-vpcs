# Create an IAP-backed bastion, installing tinyproxy from GCS bucket
module "bastion" {
  source                     = "terraform-google-modules/bastion-host/google"
  version                    = "2.10.0"
  project                    = var.project_id
  service_account_name       = format("%s-bastion", var.prefix)
  name                       = format("%s-bastion", var.prefix)
  name_prefix                = format("%s-bastion", var.prefix)
  fw_name_allow_ssh_from_iap = format("%s-allow-iap-ssh-bastion", var.prefix)
  network                    = module.management.network_self_link
  subnet                     = local.mgt_subnet
  zone                       = var.bastion_zone
  members                    = []
  labels                     = local.noncfe_resource_labels
  # Default Bastion instance is CentOS; install tinyproxy from GCS
  startup_script = <<EOD
#!/bin/sh
error()
{
  echo "$0: ERROR: $*" >/dev/ttyS0
  exit 1
}

info()
{
  echo "$0: INFO: $*" >/dev/ttyS0
}

# Network might not be accessible yet, retry until auth token is retrieved from
# metadata server
attempt=0
while [ "$${attempt:-0}" -lt 10 ]; do
    auth_token="$(curl -sf -H 'Metadata-Flavor: Google' 'http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token?alt=text' | awk '/access_token/ {print $2}')"
    retval=$?
    if [ "$${retval}" -eq 0 ]; then
        break
    fi
    info "Curl of auth token failed with exit code $${retval}; sleeping before retry"
    sleep 10
    attempt=$((attempt+1))
done
[ "$${attempt}" -ge 10 ] && \
    errpr "Failed to get auth token from metadata server"
attempt=0
while [ "$${attempt:-0}" -lt 10 ]; do
    curl -sLf --retry 20 -H "Authorization: Bearer $${auth_token}" \
            -o /var/tmp/tinyproxy.rpm "${var.install_tinyproxy_url}"
    if [ "$?" -eq 0 ]; then
        break
    fi
    info "Download of ${var.install_tinyproxy_url} failed: curl exit code: $?; sleeping before retry"
    sleep 10
    attempt=$((attempt+1))
done
[ "$${attempt}" -ge 10 ] && \
    error "Failed to get download tinyproxy RPM from GCS bucket"
rpm -iv /var/tmp/tinyproxy.rpm || error "Error installing tinyproxy: $?"
rm -f /var/tmp/tinyproxy.rpm || error "Error deleting tinyproxy rpm: $?"
systemctl daemon-reload
systemctl stop tinyproxy
# Enable reverse proxy only mode and allow access from all sources; IAP is
# enforcing access to the VM.
sed -i -e '/^#\?ReverseOnly/cReverseOnly Yes' \
    -e '/^Allow /d' \
    /etc/tinyproxy/tinyproxy.conf
systemctl enable tinyproxy
systemctl start tinyproxy
EOD
}

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
