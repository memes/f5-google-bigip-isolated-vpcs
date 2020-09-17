# Use this file to set Terraform variables shared by all solution modules
project_id  = "f5-gcs-4138-sales-cloud-sales"
tf_sa_email = "terraform@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
install_cloud_libs = [
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-cloud-libs.tar.gz?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-cloud-libs-gce.tar.gz?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-appsvcs-3.22.1-1.noarch.rpm?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-declarative-onboarding-1.15.0-3.noarch.rpm?alt=media",
  "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ff5-cloud-failover-1.5.0-0.noarch.rpm?alt=media"
]
install_tinyproxy = "https://storage.googleapis.com/storage/v1/b/automation-factory-f5-gcs-4138-sales-cloud-sales/o/misc%2Ftinyproxy-1.8.3-2.el7.x86_64.rpm?alt=media"
cloud_libs_bucket = "automation-factory-f5-gcs-4138-sales-cloud-sales"
