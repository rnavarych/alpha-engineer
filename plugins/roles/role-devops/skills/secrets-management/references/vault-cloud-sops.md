# HashiCorp Vault, Cloud Secret Managers, SOPS, and Sealed Secrets

## When to load
Load when setting up HashiCorp Vault, configuring AWS Secrets Manager or GCP Secret Manager,
encrypting secrets with SOPS or Sealed Secrets, or designing rotation policies.

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
