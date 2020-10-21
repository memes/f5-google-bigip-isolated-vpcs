# This module has been tested with Terraform 0.12 only.
#
# Note: GCS backend requires the current user to have valid application-default
# credentials. An error like "... failed: dialing: google: could not find default
# credenitals" indicates that the calling user must (re-)authenticate application
# default credentials using `gcloud auth application-default login`.
terraform {
  required_version = "~> 0.12"
  # The location and path for GCS state storage must be specified in an environment
  # file(s) via `-backend-config env/ENV/base.config`
  backend "gcs" {}
}

# Provider and Terraform service account impersonation is handled in providers.tf

locals {
  # All resources should be in the same region for this demo
  region = element(distinct([for z in concat(var.bigip_zones, [var.bastion_zone]) : replace(z, "/-[a-z]$/", "")]), 0)
  # Generate a CFE label value, if not provided
  cfe_label_value = coalesce(var.cfe_label_value, var.prefix)
  # Ensure that the labels to be applied to CFE participants have the designated label key-value pair
  cfe_resource_labels = merge(var.labels, { "${var.cfe_label_key}" = local.cfe_label_value })
  # Ensure that the resources that are *NOT* related to CFE do not include the CFE label key-value pair
  noncfe_resource_labels = { for k, v in var.labels : k => v if k != var.cfe_label_key }
}

# Random name for CFE bucket
resource "random_id" "bucket" {
  byte_length = 8
}

# Create CFE bucket - use a random value as part of the name so that new bucket
# can be created with same prefix without waiting.
module "cfe_bucket" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "1.7.2"
  project_id = var.project_id
  prefix     = var.prefix
  names      = [random_id.bucket.hex]
  force_destroy = {
    "${random_id.bucket.hex}" = true
  }
  location          = "US"
  set_admin_roles   = false
  set_creator_roles = false
  set_viewer_roles  = true
  viewers           = [format("serviceAccount:%s", local.bigip_sa)]
  labels            = local.cfe_resource_labels
}

# If a cloud libs GCS bucket name is given, make sure BIG-IP can download from it
resource "google_storage_bucket_iam_member" "cloud_libs_bigip" {
  for_each = toset([var.cloud_libs_bucket])
  bucket   = each.value
  role     = "roles/storage.objectViewer"
  member   = module.bigip_sa.iam_emails["big-ip"]
}

# If a cloud libs GCS bucket name is given, make sure bastion can download from it
resource "google_storage_bucket_iam_member" "cloud_libs_bastion" {
  for_each = toset([var.cloud_libs_bucket])
  bucket   = each.value
  role     = "roles/storage.objectViewer"
  member   = format("serviceAccount:%s", module.bastion.service_account)
}
