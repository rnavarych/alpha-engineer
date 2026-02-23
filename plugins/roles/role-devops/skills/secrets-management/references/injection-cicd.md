# Zero-Trust Secret Injection, Environment Variables, and CI/CD Secrets

## When to load
Load when configuring runtime secret injection into containers, setting up Vault Agent Injector,
CSI Secret Store Driver, managing .env files, or hardening CI/CD pipeline secret handling.

## Zero-Trust Secret Injection

- Inject secrets at runtime, never at build time. Containers should start without secrets baked in.
- Use sidecar or init-container patterns to fetch secrets from Vault before the application starts.
- **Vault Agent Injector** (Kubernetes) automatically injects secrets into pod file systems via annotations — no application code changes required.
- Use **CSI Secret Store Driver** to mount secrets from Vault, AWS Secrets Manager, or Azure Key Vault as Kubernetes volumes. Supports sync to Kubernetes Secrets for compatibility with existing workloads.
- Prefer **file-based secret injection** over environment variables. Environment variables can leak via process listings, error reporting, and child processes.

### Vault Agent Injector Annotations Pattern

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "myapp"
  vault.hashicorp.com/agent-inject-secret-config.env: "secret/data/myapp/config"
  vault.hashicorp.com/agent-inject-template-config.env: |
    {{- with secret "secret/data/myapp/config" -}}
    export DB_PASSWORD="{{ .Data.data.db_password }}"
    export API_KEY="{{ .Data.data.api_key }}"
    {{- end }}
```

### CSI Secret Store Driver Pattern

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "prod/myapp/db"
        objectType: "secretsmanager"
```

## Environment Variable Management

- Use `.env` files for local development only. Never commit them to Git; add `.env` to `.gitignore`.
- Provide a `.env.example` or `.env.template` with placeholder values and documentation for each variable.
- In production, inject environment variables from the secret store (Kubernetes Secrets, cloud secret managers) or a Vault sidecar.
- Validate required environment variables at application startup. Fail fast with a clear error message if a secret is missing.

### Startup Validation Pattern (Node.js)

```typescript
const REQUIRED_ENV = ['DB_URL', 'API_SECRET', 'JWT_KEY'] as const;

for (const key of REQUIRED_ENV) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}
```

## CI/CD Secrets Handling

- Store CI/CD secrets in the platform's native secret store: GitHub Secrets, GitLab CI Variables (masked and protected), Jenkins Credentials.
- Scope secrets to the narrowest context: repository-level, not organization-level; environment-specific, not global.
- Use **OIDC federation** (GitHub Actions OIDC, GitLab CI OIDC) to authenticate to cloud providers without storing long-lived credentials. Zero static credentials in the pipeline.
- Audit CI/CD secret access. Review which pipelines and workflows use which secrets quarterly.
- Never echo or print secrets in CI logs. Verify that masking is working with a test run that intentionally references the secret.

### GitHub Actions OIDC to AWS Pattern

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/github-actions-deploy
      aws-region: us-east-1
```

### GitHub Actions OIDC to GCP Pattern

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github/providers/github
    service_account: deploy@project.iam.gserviceaccount.com
```

## Best Practices Summary

1. No secrets in source code, Dockerfiles, or CI configs
2. Centralized secret store (Vault, cloud-native, or SOPS)
3. Automated rotation with defined schedules
4. Least-privilege access policies per service
5. Audit logging enabled for all secret access
6. Runtime injection, not build-time baking
7. OIDC federation for CI/CD cloud authentication
8. `.env` files excluded from version control
