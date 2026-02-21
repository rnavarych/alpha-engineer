---
name: secrets-management
description: |
  Secrets management expertise covering HashiCorp Vault, AWS Secrets Manager,
  GCP Secret Manager, SOPS, Kubernetes sealed secrets, rotation policies,
  zero-trust injection, environment variable management, and CI/CD secrets handling.
allowed-tools: Read, Grep, Glob, Bash
---

# Secrets Management

## Core Principles

- Secrets are any sensitive data: API keys, database credentials, TLS certificates, tokens, encryption keys.
- **Never** store secrets in source code, Dockerfiles, CI pipeline files, or application configuration committed to Git.
- Encrypt secrets at rest and in transit. Audit all access. Rotate regularly. Revoke immediately when compromised.
- Follow the principle of least privilege: each service gets only the secrets it needs, scoped to the minimum permissions.

## HashiCorp Vault

- Deploy Vault in HA mode with auto-unseal (AWS KMS, GCP Cloud KMS, Azure Key Vault) for production workloads.
- Use the **KV v2** secrets engine for static secrets with versioning and soft-delete capabilities.
- Enable **dynamic secrets** for databases: Vault generates short-lived credentials on demand, eliminating shared long-lived passwords.
- Authenticate applications using Kubernetes auth (ServiceAccount tokens), AWS IAM auth, or AppRole for non-cloud workloads.
- Define granular **policies** that restrict each application to specific secret paths and operations.
- Enable the **audit backend** to log every secret access for compliance and forensic analysis.

```hcl
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "database/creds/myapp-readonly" {
  capabilities = ["read"]
}
```

## AWS Secrets Manager and GCP Secret Manager

- Use **AWS Secrets Manager** for AWS-native workloads. It supports automatic rotation for RDS, Redshift, and DocumentDB credentials.
- Use **GCP Secret Manager** for GCP workloads. Integrate with Cloud Run and GKE via mounted volumes or environment variable injection.
- Define resource policies to restrict which IAM roles can access each secret. Avoid wildcard access.
- Enable automatic rotation with Lambda functions (AWS) or Cloud Functions (GCP). Set rotation intervals to 30-90 days.
- Use versioned secrets: deploy new versions before rotating, so applications can gracefully transition.

## SOPS (Secrets OPerationS)

- Use Mozilla SOPS to encrypt secret values in YAML, JSON, or `.env` files while keeping keys in plaintext for readability.
- Encrypt with cloud KMS keys (AWS KMS, GCP KMS, Azure Key Vault) or PGP keys for local development.
- Commit encrypted files to Git safely. The structure is visible, but values are encrypted.
- Integrate SOPS decryption into CI/CD pipelines and Kubernetes deployments with the SOPS operator or Helm secrets plugin.

```yaml
# Encrypted with SOPS - keys visible, values encrypted
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
data:
  DB_PASSWORD: ENC[AES256_GCM,data:abc123...,type:str]
  API_KEY: ENC[AES256_GCM,data:def456...,type:str]
```

## Kubernetes Sealed Secrets

- Use **Bitnami Sealed Secrets** to encrypt Kubernetes Secret manifests that can be safely stored in Git.
- The SealedSecret controller running in the cluster decrypts them into regular Kubernetes Secrets.
- Seal secrets with `kubeseal` CLI using the cluster's public key. Only the specific cluster can decrypt.
- Re-seal secrets when rotating the controller's key pair. Plan key rotation on a 90-day cycle.

## Rotation Policies

- Define rotation schedules by secret type:
  - **Database credentials**: 30-90 days, automated via Vault or cloud-native rotation
  - **API keys**: 90 days or on team member departure
  - **TLS certificates**: automated via cert-manager (Let's Encrypt) or before expiry
  - **SSH keys**: 90 days, centrally managed
  - **Service account tokens**: short-lived (1 hour) where possible, 90 days otherwise
- Implement zero-downtime rotation: issue new credentials, update consumers, revoke old credentials.
- Automate rotation end-to-end. Manual rotation processes are forgotten and become security debt.

## Zero-Trust Secret Injection

- Inject secrets at runtime, never at build time. Containers should start without secrets baked in.
- Use sidecar or init-container patterns to fetch secrets from Vault before the application starts.
- Vault Agent Injector (Kubernetes) automatically injects secrets into pod file systems via annotations.
- Use CSI Secret Store Driver to mount secrets from Vault, AWS Secrets Manager, or Azure Key Vault as Kubernetes volumes.
- Prefer file-based secret injection over environment variables. Environment variables can leak via process listings and error reporting.

## Environment Variable Management

- Use `.env` files for local development only. Never commit them to Git; add `.env` to `.gitignore`.
- Provide a `.env.example` or `.env.template` with placeholder values and documentation for each variable.
- In production, inject environment variables from the secret store (Kubernetes Secrets, cloud secret managers) or a Vault sidecar.
- Validate required environment variables at application startup. Fail fast with a clear error message if a secret is missing.

## CI/CD Secrets Handling

- Store CI/CD secrets in the platform's native secret store: GitHub Secrets, GitLab CI Variables (masked and protected), Jenkins Credentials.
- Scope secrets to the narrowest context: repository-level, not organization-level; environment-specific, not global.
- Use OIDC federation (GitHub Actions OIDC, GitLab CI OIDC) to authenticate to cloud providers without storing long-lived credentials.
- Audit CI/CD secret access. Review which pipelines and workflows use which secrets quarterly.
- Never echo or print secrets in CI logs. Verify that masking is working with a test run that intentionally references the secret.

## Best Practices Checklist

1. No secrets in source code, Dockerfiles, or CI configs
2. Centralized secret store (Vault, cloud-native, or SOPS)
3. Automated rotation with defined schedules
4. Least-privilege access policies per service
5. Audit logging enabled for all secret access
6. Runtime injection, not build-time baking
7. OIDC federation for CI/CD cloud authentication
8. `.env` files excluded from version control
