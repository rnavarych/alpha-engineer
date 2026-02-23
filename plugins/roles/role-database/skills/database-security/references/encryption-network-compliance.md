# Encryption, Network Security, and Compliance

## When to load
Load when configuring TLS/SSL for database connections, implementing column-level encryption, hardening network access, applying data masking for non-production, or meeting PCI DSS / HIPAA / GDPR / SOX requirements.

## Encryption in Transit (TLS/SSL)

### PostgreSQL
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

### MySQL
```ini
[mysqld]
require_secure_transport = ON
ssl_cert = /etc/ssl/server.crt
ssl_key = /etc/ssl/server.key
ssl_ca = /etc/ssl/ca.crt
tls_version = TLSv1.3
```

## Encryption at Rest

| Engine | Method |
|--------|--------|
| PostgreSQL | Filesystem encryption (LUKS, dm-crypt), pgcrypto for column-level |
| MySQL | InnoDB TDE: `innodb_encrypt_tables=ON` |
| MongoDB | WiredTiger: `--enableEncryption --encryptionKeyFile` |
| SQL Server | TDE: `CREATE DATABASE ENCRYPTION KEY` |
| Cloud managed | Default encryption with AWS KMS, GCP CMEK, Azure Key Vault |

### Column-Level Encryption (pgcrypto)
```sql
CREATE EXTENSION pgcrypto;

-- Encrypt
INSERT INTO users (email, ssn_encrypted)
VALUES ('user@example.com', pgp_sym_encrypt('123-45-6789', 'encryption_key'));

-- Decrypt
SELECT email, pgp_sym_decrypt(ssn_encrypted::bytea, 'encryption_key') AS ssn
FROM users WHERE id = 1;

-- Prefer application-level encryption: encrypt in app, store ciphertext
-- Database never sees plaintext — better for compliance
```

## SQL Injection Prevention

```python
# WRONG — SQL injection vulnerable
cursor.execute(f"SELECT * FROM users WHERE id = {user_input}")

# RIGHT — Parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_input,))
```

Additional defenses:
1. Input validation — whitelist allowed characters
2. Stored procedures — encapsulate queries, control access to base tables
3. Least privilege — application user has minimal permissions
4. WAF rules — block common SQL injection patterns
5. ORM — use query builders (Prisma, SQLAlchemy, GORM)

## Network Security

```
Best practices:
1. Database never on public internet
2. VPC/VNet: database in private subnet, no public IP
3. Security groups: allow only application servers on database port
4. Private endpoints: AWS PrivateLink, GCP Private Service Connect
5. Bastion/jump host for admin access with MFA and session recording

# AWS: disable public access
aws rds modify-db-instance --db-instance-id mydb --no-publicly-accessible
```

## Data Masking

### Static Masking (Non-Production)
```sql
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
CREATE VIEW users_masked AS
SELECT id, name,
       CASE WHEN current_user = 'admin' THEN email
            ELSE regexp_replace(email, '(.).*@', '\1***@') END AS email,
       CASE WHEN current_user = 'admin' THEN ssn
            ELSE 'XXX-XX-' || RIGHT(ssn, 4) END AS ssn
FROM users;

-- SQL Server built-in
ALTER TABLE users ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE users ALTER COLUMN ssn ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)');
```

## Compliance Requirements

| Regulation | Key Database Requirements |
|-----------|--------------------------|
| **PCI DSS** | Encrypt cardholder data, audit access, restrict DB access, quarterly vulnerability scans |
| **HIPAA** | Encrypt PHI at rest/transit, audit all PHI access, BAA with cloud provider |
| **GDPR** | Right to erasure, data portability, consent tracking, data residency |
| **SOX** | Audit trails for financial data, access controls, segregation of duties |
| **SOC 2** | Access controls, monitoring, incident response, encryption, change management |
