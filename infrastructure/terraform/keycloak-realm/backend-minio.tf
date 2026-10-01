terraform {
  backend "s3" {
    bucket = "brightlab-bucket"
    key    = "keycloak-realm/terraform.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "https://minio.lbrightlab.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true

    # Credentials - use the values configured for the MinIO tenant:
    # export AWS_ACCESS_KEY_ID="<minio-access-key>"
    # export AWS_SECRET_ACCESS_KEY="<minio-secret-key>"
    # export AWS_ENDPOINT_URL_S3="https://minio.lbrightlab.com"
  }
}
