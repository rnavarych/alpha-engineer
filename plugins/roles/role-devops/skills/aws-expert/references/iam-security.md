# AWS IAM, Security Services, and Multi-Account Strategy

## When to load
Load when designing IAM policies, configuring IRSA/Pod Identity, setting up Organizations/SCPs,
working with KMS, Secrets Manager, CloudTrail, GuardDuty, or Security Hub.

## IAM and Identity

### Least-Privilege IAM Design
- Never use `Action: "*"` or `Resource: "*"` in production policies. Scope every statement to exact actions and ARN patterns.
- Prefer **IAM Roles** over IAM Users for all programmatic access. Attach roles to EC2 instances, ECS tasks, Lambda functions, and EKS pods.
- Use **IAM Permission Boundaries** to cap the maximum permissions a delegated admin can grant, enabling safe developer self-service without privilege escalation risk.
- Enable **Service Control Policies (SCPs)** at the AWS Organizations level to enforce guardrails across all accounts: prevent disabling CloudTrail, block non-approved regions, require MFA for sensitive actions.
- Use **IAM Identity Center (SSO)** for centralized human access to multiple accounts. Assign Permission Sets instead of individual account-level IAM users.
- Enforce **MFA** for the root account and all IAM users that exist. Rotate access keys automatically via Secrets Manager or use OIDC-based keyless authentication from CI/CD.

### IRSA (IAM Roles for Service Accounts)
- Bind Kubernetes service accounts to IAM roles via OpenID Connect. Pods assume the role at runtime without static credentials.
- Create the OIDC provider for the EKS cluster, create an IAM role with a trust policy scoped to the specific namespace and service account name.
- Use `eks.amazonaws.com/role-arn` annotation on the Kubernetes ServiceAccount. AWS SDK automatically uses the OIDC token from the pod's projected volume.
- Scope trust policies tightly: `StringEquals sts:ExternalId` or `StringLike` on the service account subject to prevent role assumption from unintended pods.

### AWS Config and Compliance
- Enable AWS Config in all regions and accounts to track resource configuration history and detect non-compliant states.
- Use managed Config rules: `restricted-ssh`, `s3-bucket-public-read-prohibited`, `iam-root-access-key-check`, `cloudtrail-enabled`.
- Use **AWS Security Hub** to aggregate findings from Config, GuardDuty, Inspector, Macie, and third-party tools into a single compliance dashboard.
- Enable **Amazon GuardDuty** in every account and region for threat detection (unusual API calls, crypto mining, compromised credentials, exfiltration signals).

## Security Services

### KMS
- Use **Customer Managed Keys (CMKs)** for envelope encryption of sensitive data. Rotate CMKs annually (automatic rotation supported).
- Use `kms:GenerateDataKey` + local symmetric encryption (envelope encryption) for large payloads. Never encrypt large data directly with KMS.
- Restrict KMS key access via **Key Policies** and IAM policies in combination. Key policies are the primary access control for CMKs.
- Use **KMS Key Aliases** for human-readable key references in application configuration.
- Enable **CloudTrail** logging for all KMS API calls — every encrypt/decrypt/sign operation is recorded.

### Secrets Manager and Parameter Store
- Use **Secrets Manager** for passwords, API keys, and certificates that require rotation. Enable **automatic rotation** using the built-in Lambda rotation function.
- Use **SSM Parameter Store SecureString** (backed by KMS) for configuration values that don't need rotation — cheaper than Secrets Manager.
- Access secrets at runtime via SDK or sidecar injection. Never embed secrets in environment variables baked into container images or Launch Templates.
- Use **Secrets Manager resource-based policies** for cross-account secret sharing without duplicating secrets.

### CloudTrail
- Enable **CloudTrail** in all regions with **multi-region trail**. Deliver to a dedicated S3 bucket in a centralized security account.
- Enable **CloudTrail Insights** for anomaly detection on write API activity.
- Enable **CloudTrail log file validation** to detect log tampering.
- Apply **S3 Object Lock** on the CloudTrail bucket with a retention period matching compliance requirements.

## Multi-Account Strategy (AWS Organizations)

- Maintain a **Landing Zone** with separate accounts per environment (dev, staging, prod) and per function (security tooling, logging, networking, shared services).
- Use **Control Tower** to automate account provisioning with guardrails, identity, and logging baseline.
- Apply **Service Control Policies** for preventive guardrails: require MFA, restrict regions, prevent public S3 buckets, block root account usage.
- Centralize **CloudTrail**, **Security Hub**, **GuardDuty**, and **Config** in a dedicated security account as a log archive.
- Use **AWS RAM (Resource Access Manager)** to share VPC subnets across accounts in the same organization (shared VPC model). Central networking team manages the Transit Gateway.
- Set up **AWS IAM Identity Center** with an identity provider (Okta, Azure AD) for centralized SSO to all accounts.
