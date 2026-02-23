---
name: secrets-management
description: |
  Secrets management expertise covering HashiCorp Vault, AWS Secrets Manager,
  GCP Secret Manager, SOPS, Kubernetes sealed secrets, rotation policies,
  zero-trust injection, environment variable management, and CI/CD secrets handling.
allowed-tools: Read, Grep, Glob, Bash
---

# Secrets Management

## When to use
- Setting up or auditing a centralized secret store (Vault, cloud-native, or SOPS)
- Configuring runtime secret injection into Kubernetes pods or containers
- Designing secret rotation schedules and automation
- Hardening CI/CD pipelines to eliminate long-lived credentials
- Reviewing whether secrets are leaking via env vars, logs, or image layers
- Implementing OIDC federation to replace static cloud credentials in pipelines

## Core principles
1. **Never at build time** — secrets injected at runtime, never baked into images or configs
2. **Files over env vars** — file-based injection doesn't leak via process listings or error reports
3. **Rotate everything automatically** — manual rotation processes become forgotten security debt
4. **Least privilege per service** — each workload gets only the secrets it needs, nothing more
5. **Audit every access** — every read from a secret store must be logged for forensic use

## Reference Files

- `references/vault-cloud-sops.md` — Core principles, HashiCorp Vault HA/auto-unseal/KV v2/dynamic secrets/Kubernetes auth/audit backend, AWS Secrets Manager and GCP Secret Manager resource policies and rotation, SOPS encryption with KMS/PGP and Helm secrets plugin, Bitnami Sealed Secrets with kubeseal and key rotation schedule, rotation policy schedules by secret type (DB/API/TLS/SSH/tokens)
- `references/injection-cicd.md` — Zero-trust runtime injection patterns, Vault Agent Injector annotations, CSI Secret Store Driver SecretProviderClass, file-based injection preference rationale, startup env var validation pattern, GitHub Secrets and GitLab CI Variables scoping, OIDC federation for AWS and GCP from GitHub Actions/GitLab CI, CI log masking verification

## Best Practices Checklist
1. No secrets in source code, Dockerfiles, or CI configs
2. Centralized secret store (Vault, cloud-native, or SOPS)
3. Automated rotation with defined schedules
4. Least-privilege access policies per service
5. Audit logging enabled for all secret access
6. Runtime injection, not build-time baking
7. OIDC federation for CI/CD cloud authentication
8. `.env` files excluded from version control
