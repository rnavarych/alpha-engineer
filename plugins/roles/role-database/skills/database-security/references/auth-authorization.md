# Authentication and Authorization

## When to load
Load when configuring database authentication (SCRAM, certificates, LDAP, IAM), implementing RBAC with least privilege, applying Row Level Security for multi-tenancy, or restricting column-level access.

## Authentication Methods

| Method | PostgreSQL | MySQL | MongoDB | Redis |
|--------|-----------|-------|---------|-------|
| **Password (SCRAM)** | SCRAM-SHA-256 (default) | caching_sha2_password | SCRAM-SHA-256 | ACL + password |
| **Certificate (X.509)** | `clientcert=verify-full` | `--ssl-mode=VERIFY_IDENTITY` | x509 auth | TLS mutual auth |
| **LDAP/AD** | `ldap` in pg_hba.conf | `authentication_ldap_simple` | LDAP proxy/native | — |
| **IAM** | RDS IAM auth | RDS IAM / Cloud SQL IAM | Atlas IAM | ElastiCache IAM |

### PostgreSQL pg_hba.conf
```
# TYPE  DATABASE  USER      ADDRESS         METHOD
local   all       all                       scram-sha-256
host    all       all       10.0.0.0/8      scram-sha-256
hostssl all       all       0.0.0.0/0       scram-sha-256
host    all       all       0.0.0.0/0       reject
```

### Password Policy
- Minimum 16 characters for service accounts
- Rotate credentials every 90 days via Vault or AWS Secrets Manager
- Never store database passwords in code or config files

## Role-Based Access Control (RBAC)

### PostgreSQL Least-Privilege Roles
```sql
CREATE ROLE app_readonly;
GRANT CONNECT ON DATABASE mydb TO app_readonly;
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly;

CREATE ROLE app_readwrite;
GRANT app_readonly TO app_readwrite;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;

CREATE USER app_user WITH PASSWORD 'secret';
GRANT app_readwrite TO app_user;
```

**Role separation:**
- Application users: Only tables/columns they need
- Reporting users: SELECT only
- Migration users: DDL + DML, separate from application user
- Admin users: Full access, MFA required, audit logged

## Row-Level Security (RLS)

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Tenant isolation
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Role-based visibility
CREATE POLICY admin_full_access ON orders
    FOR ALL TO admin_role
    USING (true);

-- Force RLS for table owners too
ALTER TABLE orders FORCE ROW LEVEL SECURITY;
```

## Column-Level Security

```sql
-- Revoke column access
REVOKE SELECT (ssn, salary) ON employees FROM app_readonly;

-- View-based masking for safe column exposure
CREATE VIEW employees_safe AS
SELECT id, name, department, hire_date FROM employees;
GRANT SELECT ON employees_safe TO app_readonly;
```

## Audit Logging

### PostgreSQL — pgAudit
```sql
CREATE EXTENSION pgaudit;
-- postgresql.conf:
pgaudit.log = 'read, write, ddl'
pgaudit.log_catalog = off
pgaudit.log_level = log
pgaudit.log_statement_once = on
-- Object-level: GRANT SELECT ON sensitive_table TO auditor;
```

### MySQL and MongoDB Audit
```sql
-- MySQL Enterprise
INSTALL PLUGIN audit_log SONAME 'audit_log.so';
SET GLOBAL audit_log_policy = 'ALL';
SET GLOBAL audit_log_format = 'JSON';
```

```yaml
# mongod.conf
auditLog:
    destination: file
    format: JSON
    path: /var/log/mongodb/audit.json
    filter: '{ atype: { $in: ["authenticate", "createCollection", "dropCollection"] } }'
```
