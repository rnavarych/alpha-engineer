# RBAC, ABAC, API Keys, Multi-Tenancy, and SSO

## When to load
Load when implementing permission systems, API key management, tenant isolation, or enterprise SSO integration.

## RBAC (Role-Based Access Control)

- Define roles: `admin`, `manager`, `editor`, `viewer`
- Assign permissions to roles, not directly to users
- Check permissions at the middleware or decorator level — before the handler executes
- Store role-permission mappings in database or configuration
- Support role hierarchy (admin inherits all manager permissions)

## ABAC (Attribute-Based Access Control)

- Evaluate policies based on: subject attributes, resource attributes, action, environment
- Use a policy engine (Casbin, OPA/Rego, Cedar) for complex rules
- Example policy: "Managers can approve expenses under $10,000 in their department"
- Cache policy decisions for performance (with appropriate TTL)

## Enforcement Points

- **API middleware**: Check permissions before handler execution
- **Service layer**: Verify authorization for business operations
- **Data layer**: Row-level security for multi-tenant data isolation
- Never rely solely on frontend checks — always enforce server-side

## API Key Management

- Generate cryptographically random keys (minimum 32 bytes, Base64 or hex encoded)
- Store only the hashed key in the database (SHA-256 or bcrypt)
- Display the full key only once at creation time — never again
- Support key rotation: allow multiple active keys per client simultaneously
- Set expiration dates and usage limits per key
- Log all API key usage for audit trails
- Implement key scoping to restrict which endpoints a key can access

## Multi-Tenancy Auth

- Include `tenantId` in JWT claims or session data
- Enforce tenant isolation at the query/data layer — every query filters by tenant
- Prevent cross-tenant data access with middleware validation before any handler executes
- Support tenant-specific auth settings (password policies, MFA requirements)
- Use separate encryption keys per tenant for sensitive data

## SSO Integration

- Support SAML 2.0 for enterprise customers — use a library, never implement SAML from scratch
- Support OIDC for modern identity providers (Google, Azure AD, Okta, Auth0)
- Implement Just-In-Time (JIT) user provisioning on first SSO login
- Map external identity provider groups to internal roles
- Handle SSO logout properly: single logout (SLO) and back-channel logout
