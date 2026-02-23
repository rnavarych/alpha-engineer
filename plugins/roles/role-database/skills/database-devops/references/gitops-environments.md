# GitOps and Multi-Environment Database Management

## When to load
Load when implementing GitOps for database configuration, managing multi-environment parity (dev/staging/production), or setting up data anonymization for non-production environments.

## GitOps Directory Structure

```
database-config/
├── terraform/
│   ├── production/
│   │   ├── main.tf          # Instance provisioning
│   │   ├── security.tf      # Security groups, IAM
│   │   └── monitoring.tf    # Alerts, dashboards
│   └── staging/
│       └── main.tf
├── migrations/
│   ├── V001__create_users.sql
│   ├── V002__create_orders.sql
│   └── V003__add_index_orders_customer.sql
├── kubernetes/
│   ├── cnpg-cluster.yaml
│   └── pgbouncer.yaml
└── monitoring/
    ├── grafana-dashboards/
    │   └── postgresql.json
    └── prometheus-rules/
        └── database-alerts.yaml
```

## Multi-Environment Parity

| Concern | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Engine version** | Same | Same | Same |
| **Schema** | Same (via migrations) | Same | Same |
| **Data** | Seed data / anonymized | Subset of production | Real data |
| **Instance size** | Minimal | Reduced | Full |
| **HA** | Single instance | Optional | Required |
| **Backup** | None | Daily | Continuous PITR |
| **Monitoring** | Basic | Full | Full + alerting |

## Data Anonymization for Non-Production

```sql
-- Create anonymized copy for staging/dev
CREATE TABLE users_anonymized AS
SELECT id,
       'user_' || id || '@dev.example.com' AS email,
       'Test User ' || id AS name,
       md5(random()::text) AS password_hash,
       created_at
FROM users;
-- Never copy production passwords, PII, or financial data to non-production
```

## Quick Reference Principles

1. **Terraform for provisioning** — all database infrastructure as code
2. **Kubernetes operators** — automated failover, backup, scaling
3. **Migrations in CI/CD** — validate → lint → test → apply
4. **Testcontainers for testing** — real database in CI, not mocks
5. **Chaos engineering** — test failover before it happens in production
6. **Environment parity** — same engine version and schema everywhere
7. **Anonymize data** — never use real PII in non-production
