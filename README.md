# Deploy BIG-IP in GCP without internet access

![pre-commit](https://github.com/memes/f5-google-bigip-isloated-vpcs/workflows/pre-commit/badge.svg)

This repo contains sample Terraform to provision a BIG-IP HA cluster with CFE on
GCP where internet access is prohibited. The files will create a Cloud DNS
private zone to shadow `*.googleapis.com` through `restricted.googleapis.com`
endpoints, and install run-time libraries from a GCS bucket.
