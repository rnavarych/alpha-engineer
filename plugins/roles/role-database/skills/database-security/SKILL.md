---
name: database-security
description: |
  Security hardening across all database engines. Authentication (SCRAM, certificate, LDAP, Kerberos), authorization (RBAC, RLS, column-level), encryption at rest and in transit (TDE, TLS/SSL), audit logging (pgAudit, MySQL audit, MongoDB audit), SQL injection prevention, network security, data masking, compliance (PCI DSS, HIPAA, GDPR, SOX). Use when hardening database security, implementing access controls, or meeting compliance requirements.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Security

## Authentication

### Authentication Methods by Engine

| Method | PostgreSQL | MySQL | MongoDB | Redis |
|--------|-----------|-------|---------|-------|
| **Password (SCRAM)** | SCRAM-SHA-256 (default) | caching_sha2_password (default) | SCRAM-SHA-256 | ACL + password |
| **Certificate (X.509)** | `clientcert=verify-full` | `--ssl-mode=VERIFY_IDENTITY` | x509 auth | TLS mutual auth |
| **LDAP/AD** | `ldap` in pg_hba.conf | `authentication_ldap_simple` plugin | LDAP proxy/native | — |
| **Kerberos** | GSSAPI | Enterprise plugin | Kerberos | — |
| **IAM** | RDS IAM auth | RDS IAM / Cloud SQL IAM | Atlas IAM | ElastiCache IAM |
| **OIDC/OAuth** | Extensions | Enterprise | Atlas OIDC | — |

### PostgreSQL pg_hba.conf
```
# TYPE  DATABASE  USER      ADDRESS         METHOD
local   all       all                       scram-sha-256
host    all       all       10.0.0.0/8      scram-sha-256
hostssl all       all       0.0.0.0/0       scram-sha-256
host    all       all       0.0.0.0/0       reject
```

### Password Policies
- Minimum 16 characters for service accounts
- Rotate credentials every 90 days (automate with Vault/AWS Secrets Manager)
- Never store database passwords in code or config files
- Use secrets management: HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager

## Authorization

### Role-Based Access Control (RBAC)

**PostgreSQL:**
```sql
-- Create roles with specific permissions
CREATE ROLE app_readonly;
GRANT CONNECT ON DATABASE mydb TO app_readonly;
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly;

CREATE ROLE app_readwrite;
GRANT app_readonly TO app_readwrite;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;

-- Application user inherits role
CREATE USER app_user WITH PASSWORD 'secret';
GRANT app_readwrite TO app_user;
```

**Principle of Least Privilege:**
- Application users: Only tables/columns they need
- Reporting users: SELECT only, no DML
- Migration users: DDL + DML, separate from application user
- Admin users: Full access, MFA required, audit logged

### Row-Level Security (RLS)

**PostgreSQL:**
```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Role-based visibility
CREATE POLICY admin_full_access ON orders
    FOR ALL TO admin_role
    USING (true);

-- Force RLS for table owners too
ALTER TABLE orders FORCE ROW LEVEL SECURITY;
```

### Column-Level Security
```sql
-- PostgreSQL: Revoke column access
REVOKE SELECT (ssn, salary) ON employees FROM app_readonly;

-- Create view that excludes sensitive columns
CREATE VIEW employees_safe AS
SELECT id, name, department, hire_date FROM employees;
GRANT SELECT ON employees_safe TO app_readonly;
```

## Encryption

### Encryption at Rest

| Engine | Method | Configuration |
|--------|--------|---------------|
| **PostgreSQL** | Filesystem encryption (LUKS, dm-crypt), pgcrypto for column-level | OS-level or cloud KMS |
| **MySQL** | InnoDB tablespace encryption (TDE) | `innodb_encrypt_tables=ON` |
| **MongoDB** | WiredTiger encryption | `--enableEncryption --encryptionKeyFile` |
| **SQL Server** | Transparent Data Encryption (TDE) | `CREATE DATABASE ENCRYPTION KEY` |
| **Oracle** | TDE (tablespace + column level) | Wallet/OKV for key management |
| **Redis** | Not built-in (use disk encryption) | OS-level encryption |
| **Cloud managed** | Default encryption with cloud KMS | AWS KMS, GCP CMEK, Azure Key Vault |

### Encryption in Transit (TLS/SSL)

**PostgreSQL:**
```
# postgresql.conf
ssl = on
ssl_cert_file = '/etc/ssl/server.crt'
ssl_key_file = '/etc/ssl/server.key'
ssl_ca_file = '/etc/ssl/ca.crt'
ssl_min_protocol_version = 'TLSv1.3'

# Force SSL in pg_hba.conf
hostssl all all 0.0.0.0/0 scram-sha-256
```

**MySQL:**
```ini
[mysqld]
require_secure_transport = ON
ssl_cert = /etc/ssl/server.crt
ssl_key = /etc/ssl/server.key
ssl_ca = /etc/ssl/ca.crt
tls_version = TLSv1.3
```

### Column-Level Encryption
```sql
-- PostgreSQL with pgcrypto
CREATE EXTENSION pgcrypto;

-- Encrypt
INSERT INTO users (email, ssn_encrypted)
VALUES ('user@example.com', pgp_sym_encrypt('123-45-6789', 'encryption_key'));

-- Decrypt
SELECT email, pgp_sym_decrypt(ssn_encrypted::bytea, 'encryption_key') AS ssn
FROM users WHERE id = 1;

-- Application-level encryption (preferred): encrypt in application, store ciphertext
-- Database never sees plaintext — better for compliance
```

## Audit Logging

### PostgreSQL (pgAudit)
```sql
-- Install
CREATE EXTENSION pgaudit;

-- postgresql.conf
pgaudit.log = 'read, write, ddl'        -- what to log
pgaudit.log_catalog = off                -- don't log system catalog queries
pgaudit.log_level = log                  -- log level
pgaudit.log_statement_once = on          -- log statement text once per statement

-- Object-level auditing
pgaudit.role = 'auditor'
GRANT SELECT ON sensitive_table TO auditor;  -- now all SELECTs on this table are logged
```

### MySQL Audit
```sql
-- Enterprise Audit Plugin
INSTALL PLUGIN audit_log SONAME 'audit_log.so';
SET GLOBAL audit_log_policy = 'ALL';

-- Percona Audit Log Plugin (open source)
INSTALL PLUGIN audit_log SONAME 'audit_log.so';
SET GLOBAL audit_log_format = 'JSON';
```

### MongoDB Audit
```yaml
# mongod.conf
auditLog:
    destination: file
    format: JSON
    path: /var/log/mongodb/audit.json
    filter: '{ atype: { $in: ["authenticate", "createCollection", "dropCollection"] } }'
```

## SQL Injection Prevention

### Parameterized Queries (Always)
```python
# WRONG — SQL injection vulnerable
cursor.execute(f"SELECT * FROM users WHERE id = {user_input}")

# RIGHT — Parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_input,))
```

### Additional Defenses
1. **Input validation**: Whitelist allowed characters, reject unexpected input
2. **Stored procedures**: Encapsulate queries, control access to base tables
3. **Least privilege**: Application user has minimal permissions
4. **WAF rules**: Block common SQL injection patterns at network level
5. **ORM**: Use query builders (Prisma, SQLAlchemy, GORM) — but verify generated SQL

## Network Security

### Best Practices
1. **Private network only**: Database should never be on public internet
2. **VPC/VNet placement**: Database in private subnet, no public IP
3. **Security groups/firewall**: Allow only application servers on database port
4. **Private endpoints**: AWS PrivateLink, GCP Private Service Connect, Azure Private Link
5. **Bastion/jump host**: For admin access, with MFA and session recording
6. **Network segmentation**: Separate database network from application network

### Cloud-Specific
```
# AWS: Security group for RDS
Inbound: TCP 5432 from sg-app-servers only
Outbound: None needed (stateful)

# Disable public access
aws rds modify-db-instance --db-instance-id mydb --no-publicly-accessible
```

## Data Masking and Anonymization

### Static Masking (for Non-Production)
```sql
-- Create masked copy for development
CREATE TABLE users_masked AS
SELECT id,
       'user_' || id || '@example.com' AS email,
       'Test User ' || id AS name,
       'XXX-XX-' || RIGHT(ssn, 4) AS ssn,
       created_at
FROM users;
```

### Dynamic Masking
```sql
-- PostgreSQL: View-based masking
CREATE VIEW users_masked AS
SELECT id, name,
       CASE WHEN current_user = 'admin' THEN email
            ELSE regexp_replace(email, '(.).*@', '\1***@') END AS email,
       CASE WHEN current_user = 'admin' THEN ssn
            ELSE 'XXX-XX-' || RIGHT(ssn, 4) END AS ssn
FROM users;

-- SQL Server: Dynamic Data Masking (built-in)
ALTER TABLE users ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE users ALTER COLUMN ssn ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)');
```

## Compliance Requirements

| Regulation | Key Database Requirements |
|-----------|--------------------------|
| **PCI DSS** | Encrypt cardholder data, audit access, restrict DB access, quarterly vulnerability scans |
| **HIPAA** | Encrypt PHI at rest/transit, audit all PHI access, access controls, BAA with cloud provider |
| **GDPR** | Right to erasure, data portability, consent tracking, DPIAs, data residency |
| **SOX** | Audit trails for financial data, change management, access controls, segregation of duties |
| **SOC 2** | Access controls, monitoring, incident response, encryption, change management |

## Security Checklist

1. **Authentication**: Strong passwords, MFA for admin, certificate auth for services
2. **Authorization**: RBAC, least privilege, RLS for multi-tenant
3. **Encryption**: TLS 1.3 in transit, encryption at rest, column-level for PII
4. **Audit logging**: All DDL, sensitive data access, authentication events
5. **Network**: Private network, security groups, no public access
6. **Patching**: Regular security updates, CVE monitoring
7. **Backup encryption**: Encrypted backups with separate key management
8. **Secrets management**: No passwords in code/config, use Vault/Secrets Manager
9. **Monitoring**: Failed login alerts, privilege escalation alerts, anomaly detection
10. **Testing**: Regular penetration testing, SQL injection scanning
