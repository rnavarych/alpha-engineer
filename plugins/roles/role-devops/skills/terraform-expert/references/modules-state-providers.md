# Terraform Module Design, State Management, and Providers

## When to load
Load when designing Terraform module structure, configuring remote backends and state locking,
managing provider versions, working with Terragrunt, or detecting configuration drift.

## HCL Module Design

- Structure modules with clear boundaries: one module per logical resource group (networking, compute, database, DNS).
- Every module exposes well-documented `variables.tf` (inputs), `outputs.tf` (outputs), and `main.tf` (resources).
- Use `variable` validation blocks to enforce constraints at plan time rather than failing at apply time.
- Publish reusable modules to a private Terraform registry or a Git repository with semantic version tags.
- Compose infrastructure by calling modules from a root configuration, keeping the root thin and declarative.

```hcl
module "vpc" {
  source  = "git::https://github.com/org/terraform-modules.git//vpc?ref=v2.1.0"
  cidr    = "10.0.0.0/16"
  azs     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  environment = var.environment
}
```

## State Management

- Always use **remote backends** (S3 + DynamoDB, GCS, Terraform Cloud) for state storage. Never commit `terraform.tfstate` to Git.
- Enable **state locking** to prevent concurrent applies that corrupt state. DynamoDB for S3 backend, built-in for Terraform Cloud.
- Organize state by environment and component: separate state files for networking, compute, and data layers to reduce blast radius.
- Use `terraform state mv` and `terraform state rm` for refactoring. Back up state before any manual state manipulation.
- Enable state file encryption at rest via the backend configuration or cloud-native encryption.

## Workspaces

- Use Terraform workspaces for lightweight environment separation when the infrastructure shape is identical (dev, staging, prod).
- For significantly different environments, prefer separate root configurations or Terragrunt to avoid workspace complexity.
- Reference the workspace name with `terraform.workspace` to parameterize resource names and tags.

## Provider Configuration

- Pin provider versions with `required_providers` constraints: `version = "~> 5.0"` for minor version flexibility.
- Use `provider` aliases for multi-region or multi-account deployments within a single configuration.
- Configure provider authentication via environment variables or instance profiles, never hardcoded credentials.

## Drift Detection

- Run `terraform plan` on a schedule (CI cron job) to detect configuration drift from manual changes.
- Alert the team when drift is detected. Either reconcile by applying the Terraform state or import the manual change.
- Use Terraform Cloud or Spacelift for continuous drift detection with automated notifications.

## Terragrunt

- Use Terragrunt to keep root configurations DRY across environments. Define shared backend config and provider config in parent `terragrunt.hcl`.
- Leverage `dependency` blocks to pass outputs between modules without hardcoding remote state references.
- Use `generate` blocks for boilerplate files (backend config, provider blocks) that vary by environment.
- Organize with a directory-per-environment, directory-per-component structure for clear separation.

## Variable Management

- Use `terraform.tfvars` per environment or pass variables via CI/CD environment variables.
- Mark sensitive variables with `sensitive = true` to suppress them from plan output and logs.
- Provide sensible defaults in `variables.tf` where possible; require explicit values for environment-specific settings.
