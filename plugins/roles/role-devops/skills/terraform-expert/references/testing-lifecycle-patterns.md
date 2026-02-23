# Terraform Testing, Lifecycle Rules, Data Sources, and Advanced Patterns

## When to load
Load when writing Terratest integration tests, configuring tflint/Checkov/tfsec security scanning,
designing lifecycle rules for zero-downtime resource replacement, or working with data sources and outputs.

## Infrastructure Testing

- **Terratest** (Go) for end-to-end integration tests: provision real infrastructure, validate behavior, tear down.
- **terraform validate** and **tflint** in CI for syntax and best-practice checks on every pull request.
- **Checkov**, **tfsec**, or **Trivy IaC** for security scanning of Terraform configurations. Fail CI on critical findings.
- **terraform plan** output saved as an artifact for review before applying in production pipelines.

### CI Pipeline Stages for Terraform
```
terraform fmt -check        # formatting gate
terraform validate          # syntax and reference check
tflint                      # best practice linting
checkov -d .                # security scanning
terraform plan              # plan output for review
# [manual approval gate for production]
terraform apply             # apply after approval
```

### Terratest Pattern

```go
func TestVpcModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../../modules/vpc",
        Vars: map[string]interface{}{
            "environment": "test",
            "cidr":        "10.99.0.0/16",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

## Lifecycle Rules and Advanced Patterns

- Use `lifecycle { create_before_destroy = true }` for zero-downtime replacements of critical resources.
- Use `prevent_destroy = true` on resources that should never be accidentally deleted (databases, S3 buckets with data).
- Use `ignore_changes` for attributes managed outside Terraform (auto-scaling group desired count, externally managed tags).
- Import existing infrastructure with `terraform import` and then write the corresponding HCL to match.

```hcl
resource "aws_db_instance" "main" {
  # ...

  lifecycle {
    prevent_destroy       = true
    ignore_changes        = [snapshot_identifier]
    create_before_destroy = false
  }
}
```

## Data Sources and Outputs

- Use `data` sources to reference existing infrastructure (VPC IDs, AMI lookups, DNS zones) without managing their lifecycle.
- Export meaningful outputs for use by other modules or CI/CD scripts: endpoint URLs, resource ARNs, IP addresses.
- Use `terraform output -json` in CI pipelines to feed values into downstream deployment steps.

```hcl
# Data source for existing VPC
data "aws_vpc" "main" {
  tags = {
    Environment = var.environment
    Name        = "main-vpc"
  }
}

# Reference in resource
resource "aws_subnet" "app" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = "10.0.10.0/24"
}

# Export for downstream use
output "app_subnet_id" {
  description = "Application subnet ID for EKS node groups"
  value       = aws_subnet.app.id
}
```

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
