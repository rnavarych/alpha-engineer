---
name: role-devops:terraform-expert
description: |
  Terraform and Infrastructure as Code expertise covering HCL module design,
  state management, workspaces, provider configuration, drift detection,
  Terragrunt, infrastructure testing, and resource lifecycle management.
allowed-tools: Read, Grep, Glob, Bash
---

# Terraform Expert

## When to use
- Designing or reviewing Terraform module structure and composition
- Configuring remote backends, state locking, or organizing state by environment
- Setting up Terragrunt for DRY multi-environment configurations
- Running infrastructure testing with Terratest, tflint, or Checkov/tfsec
- Detecting and reconciling configuration drift
- Implementing lifecycle rules for zero-downtime resource replacement

## Core principles
1. **Remote state always** — never commit `terraform.tfstate`, always lock concurrent applies
2. **Modules are versioned** — Git tags or registry versions, never floating references
3. **Plan before apply** — saved plan artifact reviewed before production apply
4. **Security scanning in CI** — Checkov or tfsec fails the pipeline on critical findings
5. **Drift is technical debt** — scheduled plan runs detect and surface manual changes before they compound

## Reference Files

- `references/modules-state-providers.md` — HCL module structure (variables.tf/outputs.tf/main.tf), variable validation blocks, Git tag versioning, remote backends (S3+DynamoDB/GCS/Terraform Cloud), state locking, blast-radius state organization, workspace use cases, provider version pinning and aliases, drift detection with scheduled CI plans and Spacelift, Terragrunt DRY patterns with dependency blocks and generate blocks, sensitive variable handling
- `references/testing-lifecycle-patterns.md` — CI pipeline stages (fmt/validate/tflint/checkov/plan/apply), Terratest Go integration test pattern with defer destroy, `prevent_destroy` and `create_before_destroy` lifecycle rules, `ignore_changes` for externally managed attributes, `terraform import` workflow, data sources for existing infrastructure, `terraform output -json` for downstream CI steps, best practices checklist

## Best Practices Checklist
1. Remote backend with state locking enabled
2. Provider versions pinned in `required_providers`
3. Modules versioned with Git tags or registry versions
4. `terraform plan` runs on every pull request
5. Security scanning (tfsec/Checkov) in CI
6. Sensitive variables marked and protected
7. State organized by environment and component
8. Resources tagged consistently for cost tracking
9. `prevent_destroy` set on stateful production resources
10. Terratest or equivalent for module integration tests
