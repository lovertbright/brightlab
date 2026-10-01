# Keycloak Realm Configuration with OpenTofu

This directory contains OpenTofu scripts to declaratively manage realms, clients, roles, and users within a running Keycloak instance. This allows you to treat your Keycloak configuration as code, ensuring it is version-controlled and repeatable.

This configuration is designed to be run **after** Keycloak has been deployed to the Kubernetes cluster.

## Prerequisites

- **OpenTofu:** You must have `tofu` installed. These scripts are written for OpenTofu, the open-source fork of Terraform.
- **Keycloak Instance:** A running Keycloak instance accessible from where you are running the `tofu` commands.
- **Keycloak Provider Credentials:** You need the Keycloak URL and admin credentials configured in `terraform.tfvars`.
- **MinIO Backend:** The `brightlab-bucket` bucket must exist on `https://minio.lbrightlab.com`.
- **AWS CLI:** Required to create or verify the MinIO backend bucket.

## Configuration Overview

- `main.tf`: Defines all the Keycloak resources to be created, such as realms, clients, roles, and users.
- `variable.tf`: Declares the input variables used in the configuration (e.g., credentials, URLs).
- `output.tf`: Defines the output values that will be displayed after applying the configuration, such as client secrets.
- `terraform.tfvars`: **(Important)** This is where you must provide your specific values for the variables, such as the Keycloak admin password and URL.
- `secret.sh`: A helper script to automate the creation of Kubernetes secrets from the OpenTofu outputs. This is useful for injecting client secrets into other applications like Grafana.

## Deployment Steps

### 1. Configure Variables

Before running OpenTofu, you must fill in the required values in the `terraform.tfvars` file. This file is intentionally ignored by Git to prevent committing secrets.

```hcl
# terraform.tfvars

kc_url        = "https://keycloak.your-domain.com/" # Replace with your Keycloak URL
kc_admin_user = "admin"
kc_admin_pass = "your-admin-password"               # Replace with your admin password
```

Use the password for the existing Keycloak `admin` account. Updating the
Kubernetes `keycloak-admin` Secret does not change the password in an existing
Keycloak database.

### 2. Configure the MinIO Backend

The backend uses the MinIO S3-compatible endpoint and stores state in
`brightlab-bucket`. Set credentials for the MinIO tenant before running
OpenTofu. Do not use stale AWS profile credentials.

```bash
export AWS_ACCESS_KEY_ID="<minio-access-key>"
export AWS_SECRET_ACCESS_KEY="<minio-secret-key>"
export AWS_DEFAULT_REGION="us-east-1"
```

The credentials must match the MinIO tenant configuration. Create the bucket
once if it does not already exist:

```bash
aws --endpoint-url https://minio.lbrightlab.com \
	s3api create-bucket --bucket brightlab-bucket
```

If the bucket already exists, the create command can be skipped.

### 3. Initialize OpenTofu

Navigate to this directory and run `init`. Use `-reconfigure` after changing
backend settings or when initializing this directory for the first time.

```bash
tofu init -reconfigure
```

### 4. Plan the Changes

Run the `plan` command to see what changes OpenTofu will make to your Keycloak instance. This is a dry run and is safe to execute.

```bash
tofu plan
```

### 5. Apply the Configuration

If the plan looks correct, apply the changes to configure Keycloak.

```bash
tofu apply --auto-approve
```

### 6. Create Kubernetes Secrets (Optional)

After applying the configuration, OpenTofu will output sensitive data like client secrets. The `secret.sh` script is designed to take these outputs and create the necessary Kubernetes secrets for other applications.

Make sure the script is executable and run it:

```bash
chmod +x secret.sh
./secret.sh
```

This script uses the `tofu output` command to fetch the required values and `kubectl` to create the secrets in the appropriate namespaces.

## Troubleshooting

### `401 Unauthorized` from the Keycloak provider

The provider must authenticate to the `master` realm before it can create a
plan. Confirm that `kc_url` has no trailing slash and that `kc_admin_user` and
`kc_admin_pass` match the current Keycloak admin account. A response containing
`invalid_grant: Invalid user credentials` indicates a password mismatch, not a
state or infrastructure change.

If the Kubernetes Secret was changed after Keycloak was initialized, reset the
existing Keycloak admin password through the Keycloak administration interface
or another authorized administrative procedure, then update `terraform.tfvars`.

If Keycloak displays “You need local access to create the initial admin user”,
the deployment is missing `KEYCLOAK_ADMIN` and `KEYCLOAK_ADMIN_PASSWORD` at
startup. Apply the Keycloak HelmRelease configuration, restart Keycloak, and
wait for the initial admin account to be created before running `tofu plan`.
