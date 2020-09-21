variable "tf_sa_email" {
  type        = string
  default     = null
  description = <<EOD
The fully-qualified email address of the Terraform service account to use for
resource creation. E.g.
tf_sa_email = "terraform@PROJECT_ID.iam.gserviceaccount.com"
EOD
}

variable "tf_sa_token_lifetime_secs" {
  type        = number
  default     = 1200
  description = <<EOD
The expiration duration for the service account token, in seconds. This value
should be high enough to prevent token timeout issues during resource creation,
but short enough that the token is useless replayed later. Default value is 1200.
EOD
}

variable "project_id" {
  type        = string
  description = <<EOD
The existing project id that will host the BIG-IP resources.
EOD
}

variable "prefix" {
  type        = string
  default     = "isolated-vpcs"
  description = <<EOD
An optional prefix to use when naming resources; default is 'isolated-vpcs'.
Override this value if you are deploying in a shared environment.
EOD
}

variable "bastion_zone" {
  type        = string
  default     = "us-central1-f"
  description = <<EOD
The GCE zone to deploy the bastion host. Default is 'us-central1-f'.
EOD
}

variable "bigip_zones" {
  type        = list(string)
  default     = ["us-central1-f", "us-central1-c"]
  description = <<EOD
The GCE zones to deploy the BIG-IP instances. Default is 'us-central1-f' and
'us-central1-c'.
EOD
}

variable "image" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-4-0-0-6-payg-good-25mbps-200618231522"
  description = <<EOD
The GCE image to use as the base for BIG-IP instances; default is latest BIG-IP v15 payg good 25mbs.
EOD
}

variable "cfe_label_key" {
  type        = string
  default     = "f5_cloud_failover_label"
  description = <<EOD
The CFE label key to assign to resources that are going to be managed by CFE.
Default value is 'f5_cloud_failover_label'.
EOD
}

variable "cfe_label_value" {
  type        = string
  default     = ""
  description = <<EOD
The CFE label value to assign to resources that are going to be managed by this
BIG-IP deployment. If left empty, a value will be generated for this deployment.
EOD
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<EOD
An optional map of label key-values to apply to all resources. Default is an
empty map.
EOD
}

variable "install_cloud_libs" {
  type        = list(string)
  description = <<EOD
Contains the URLs for F5's Cloud Libs required for BIG-IP w/CFE on-boarding,
overriding the default download patch from cdn.f5.com and github.com.
EOD
}


variable "install_tinyproxy_url" {
  type        = string
  description = <<EOD
Contains the URL for tinyproxy RPM to install on bastion host.
EOD
}

variable "cloud_libs_bucket" {
  type        = string
  default     = ""
  description = <<EOD
An optional GCS bucket name to which the BIG-IP service account will be granted
read-only access. Default is empty string.

See `install_cloud_libs`.
EOD
}
