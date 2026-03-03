---
name: role-database:database-security
description: |
  Security hardening across all database engines. Authentication (SCRAM, certificate, LDAP, Kerberos), authorization (RBAC, RLS, column-level), encryption at rest and in transit (TDE, TLS/SSL), audit logging (pgAudit, MySQL audit, MongoDB audit), SQL injection prevention, network security, data masking, compliance (PCI DSS, HIPAA, GDPR, SOX). Use when hardening database security, implementing access controls, or meeting compliance requirements.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Security

## Reference Files

Load from `references/` based on what's needed:

### references/auth-authorization.md
Authentication methods comparison (SCRAM, certificates, LDAP, IAM) across PostgreSQL, MySQL, MongoDB, Redis.
PostgreSQL pg_hba.conf patterns, password policy guidance.
RBAC with least-privilege role setup in PostgreSQL.
Row Level Security policies (tenant isolation, admin override, FORCE RLS).
Column-level security via REVOKE and views.
Audit logging: pgAudit config, MySQL Enterprise audit, MongoDB audit filter.
Load when: configuring authentication, setting up access controls, or implementing audit logging.

### references/encryption-network-compliance.md
TLS/SSL configuration for PostgreSQL and MySQL (TLSv1.3).
Encryption at rest comparison table (TDE, WiredTiger, cloud KMS).
Column-level encryption with pgcrypto (encrypt/decrypt examples).
SQL injection prevention: parameterized queries and defense layers.
Network security best practices (private subnet, security groups, PrivateLink).
Static and dynamic data masking.
Compliance requirements table (PCI DSS, HIPAA, GDPR, SOX, SOC 2).
Load when: configuring encryption, hardening network access, or meeting compliance requirements.
