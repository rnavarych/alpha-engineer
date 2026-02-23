---
name: database-devops
description: |
  Infrastructure-as-code and automation for databases. Terraform modules (RDS, Cloud SQL, Atlas, Azure Database), Kubernetes operators (CloudNativePG, Percona, CrunchyData PGO, Vitess, MongoDB, Redis), Helm charts, GitOps for database config. Schema migration in CI/CD pipelines. Database testing in CI (Testcontainers, docker-compose). Chaos engineering for databases. Use when automating database provisioning, integrating databases into CI/CD, or managing database infrastructure as code.
allowed-tools: Read, Grep, Glob, Bash
---

# Database DevOps

## Reference Files

Load from `references/` based on what's needed:

### references/terraform-kubernetes.md
Terraform for AWS RDS PostgreSQL (parameter groups, encryption, monitoring), Google Cloud SQL, MongoDB Atlas.
Load when: provisioning database infrastructure as code with Terraform.

### references/kubernetes-operators.md
CloudNativePG Kubernetes cluster YAML with S3 backup, Prometheus monitoring, and resource limits.
Comparison table of all major K8s database operators (CrunchyData PGO, Percona, Vitess, Redis, Strimzi, ClickHouse).
Load when: deploying or managing databases on Kubernetes.

### references/cicd-testing.md
GitHub Actions pipeline: Flyway validate, Atlas lint, staging apply, production gate.
Testcontainers in TypeScript and Python for real-database CI tests.
Docker Compose local dev setup with healthchecks.
Chaos engineering scenarios and Toxiproxy configuration.
Load when: integrating migrations into CI/CD or testing database behavior under failure.

### references/gitops-environments.md
GitOps directory structure (terraform, migrations, kubernetes, monitoring).
Multi-environment parity matrix (dev/staging/production).
Data anonymization SQL for non-production environments.
Load when: setting up GitOps workflows or managing environment consistency.
