# Use this file to set Terraform variables required by demo

# The unique GCP project ID that will host the demo resources
project_id = "f5-gcs-4138-sales-cloud-sales"

# Use service account impersonation and execute resource creation as Terraform SA
# NOTE: if you have not setup service account impersonation, remove this entry
# to run the Terraform using your credentials.
tf_sa_email = "terraform@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"

# Override the standard CFE module 'install_cloud_libs' to use authenticated URL
# to GCS storage. This will use the restricted.googleapis.com DNS masked entry.
# NOTE: these URLs must be to a location that allows the BIG-IP service account
# to downlaod the contents. If this is a GCS bucket which you must have prepared
# in advance, the BIG-IP service account must have object read permissions -
# see also `cloud_libs_bucket` variable below.
install_cloud_libs = [
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-cloud-libs.tar.gz?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-cloud-libs-gce.tar.gz?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-appsvcs-3.22.1-1.noarch.rpm?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-declarative-onboarding-1.15.0-3.noarch.rpm?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-cloud-failover-1.5.0-0.noarch.rpm?alt=media"
]

# Can't reach EPEL so provide a GCS based tinyproxy RPM to install on bastion
install_tinyproxy_url = "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ftinyproxy-1.8.3-2.el7.x86_64.rpm?alt=media"
# Make sure the BIG-IP and Bastion have storage.objectViewer on the GCS bucket
# holding the files to install
cloud_libs_bucket = "automation-factory-f5-gcs-4138-sales-cloud-sales"
