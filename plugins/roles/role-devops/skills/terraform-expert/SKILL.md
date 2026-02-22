---
name: terraform-expert
description: |
  Terraform and Infrastructure as Code expertise covering HCL module design,
  state management, workspaces, provider configuration, drift detection,
  Terragrunt, infrastructure testing, and resource lifecycle management.
allowed-tools: Read, Grep, Glob, Bash
---

# Terraform Expert

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

## Infrastructure Testing

- **Terratest** (Go) for end-to-end integration tests: provision real infrastructure, validate behavior, tear down.
- **terraform validate** and **tflint** in CI for syntax and best-practice checks on every pull request.
- **Checkov**, **tfsec**, or **Trivy IaC** for security scanning of Terraform configurations. Fail CI on critical findings.
- **terraform plan** output saved as an artifact for review before applying in production pipelines.

## Variable Management

- Use `terraform.tfvars` per environment or pass variables via CI/CD environment variables.
- Mark sensitive variables with `sensitive = true` to suppress them from plan output and logs.
- Provide sensible defaults in `variables.tf` where possible; require explicit values for environment-specific settings.

## Lifecycle Rules and Advanced Patterns

- Use `lifecycle { create_before_destroy = true }` for zero-downtime replacements of critical resources.
- Use `prevent_destroy = true` on resources that should never be accidentally deleted (databases, S3 buckets with data).
- Use `ignore_changes` for attributes managed outside Terraform (auto-scaling group desired count, externally managed tags).
- Import existing infrastructure with `terraform import` and then write the corresponding HCL to match.

## Data Sources and Outputs

- Use `data` sources to reference existing infrastructure (VPC IDs, AMI lookups, DNS zones) without managing their lifecycle.
- Export meaningful outputs for use by other modules or CI/CD scripts: endpoint URLs, resource ARNs, IP addresses.
- Use `terraform output -json` in CI pipelines to feed values into downstream deployment steps.

## Best Practices Checklist

1. Remote backend with state locking enabled
2. Provider versions pinned in `required_providers`
3. Modules versioned with Git tags or registry versions
4. `terraform plan` runs on every pull request
5. Security scanning (tfsec/Checkov) in CI
6. Sensitive variables marked and protected
7. State organized by environment and component
8. Resources tagged consistently for cost tracking
