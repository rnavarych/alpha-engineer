---
name: database-devops
description: |
  Infrastructure-as-code and automation for databases. Terraform modules (RDS, Cloud SQL, Atlas, Azure Database), Kubernetes operators (CloudNativePG, Percona, CrunchyData PGO, Vitess, MongoDB, Redis), Helm charts, GitOps for database config. Schema migration in CI/CD pipelines. Database testing in CI (Testcontainers, docker-compose). Chaos engineering for databases. Use when automating database provisioning, integrating databases into CI/CD, or managing database infrastructure as code.
allowed-tools: Read, Grep, Glob, Bash
---

# Database DevOps

## Infrastructure as Code

### Terraform for Database Provisioning

**AWS RDS PostgreSQL:**
```hcl
resource "aws_db_instance" "main" {
  identifier     = "myapp-production"
  engine         = "postgres"
  engine_version = "16.2"
  instance_class = "db.r6g.xlarge"

  allocated_storage     = 100
  max_allocated_storage = 500    # autoscaling
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  db_name  = "myapp"
  username = "admin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn

  parameter_group_name = aws_db_parameter_group.pg16.name

  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "myapp-final-snapshot"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_db_parameter_group" "pg16" {
  family = "postgres16"
  name   = "myapp-pg16"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,auto_explain"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # log queries > 1 second
  }
}
```

**Google Cloud SQL:**
```hcl
resource "google_sql_database_instance" "main" {
  name             = "myapp-production"
  database_version = "POSTGRES_16"
  region           = "us-central1"

  settings {
    tier              = "db-custom-4-16384"  # 4 vCPU, 16 GB
    availability_type = "REGIONAL"            # HA

    disk_size     = 100
    disk_type     = "PD_SSD"
    disk_autoresize = true

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 14
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  }

  deletion_protection = true
}
```

**MongoDB Atlas:**
```hcl
resource "mongodbatlas_cluster" "main" {
  project_id = mongodbatlas_project.myproject.id
  name       = "production"

  provider_name               = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M30"

  cluster_type = "REPLICASET"
  num_shards   = 1

  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "US_EAST_1"
      electable_nodes = 3
      priority        = 7
    }
  }

  auto_scaling_compute_enabled = true
  auto_scaling_compute_scale_down_enabled = true

  backup_enabled = true
  pit_enabled    = true

  encryption_at_rest_provider = "AWS"
}
```

## Kubernetes Operators

### CloudNativePG (PostgreSQL)
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: myapp-db
spec:
  instances: 3
  imageName: ghcr.io/cloudnative-pg/postgresql:16.2

  storage:
    size: 100Gi
    storageClass: gp3

  postgresql:
    parameters:
      shared_buffers: "4GB"
      effective_cache_size: "12GB"
      work_mem: "64MB"
      shared_preload_libraries: "pg_stat_statements"

  bootstrap:
    initdb:
      database: myapp
      owner: app

  backup:
    barmanObjectStore:
      destinationPath: "s3://myapp-backups/pg/"
      s3Credentials:
        accessKeyId:
          name: s3-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: s3-creds
          key: SECRET_ACCESS_KEY
    retentionPolicy: "14d"

  monitoring:
    enablePodMonitor: true

  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "16Gi"
```

### Other Kubernetes Operators

| Operator | Database | Key Features |
|----------|----------|-------------|
| **CrunchyData PGO** | PostgreSQL | Backup, HA, monitoring, connection pooling |
| **Percona Operator for PG** | PostgreSQL | pgBouncer, PMM monitoring |
| **Percona Operator for MySQL** | MySQL | Percona XtraDB Cluster, Group Replication |
| **Percona Operator for MongoDB** | MongoDB | Replica sets, sharding, backup |
| **Vitess Operator** | MySQL (Vitess) | Sharding, MoveTables, schema management |
| **Redis Operator** | Redis | Cluster, Sentinel, failover |
| **Strimzi** | Kafka | Cluster, topics, users, MirrorMaker |
| **MongoDB Community Operator** | MongoDB | Replica sets, basic management |
| **ClickHouse Operator** | ClickHouse | Cluster management, sharding |

## Schema Migration in CI/CD

### GitHub Actions Pipeline
```yaml
name: Database Migration

on:
  push:
    paths:
      - 'migrations/**'
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate migrations
        run: |
          # Check migration file naming
          flyway info -url=${{ secrets.STAGING_DB_URL }}
          flyway validate -url=${{ secrets.STAGING_DB_URL }}

      - name: Apply to staging
        run: flyway migrate -url=${{ secrets.STAGING_DB_URL }}

      - name: Run integration tests
        run: pytest tests/integration/ --db-url=${{ secrets.STAGING_DB_URL }}

      - name: Apply to production
        if: github.ref == 'refs/heads/main'
        run: flyway migrate -url=${{ secrets.PROD_DB_URL }}
        environment: production
```

### Migration Safety in CI
```yaml
# Atlas schema linting (catch destructive changes)
- name: Lint migrations
  run: |
    atlas migrate lint \
        --dir "file://migrations" \
        --dev-url "docker://postgres/16" \
        --latest 1
    # Catches: data-dependent changes, backward incompatible, missing indexes
```

## Database Testing in CI

### Testcontainers
```typescript
// TypeScript (Node.js)
import { PostgreSqlContainer } from '@testcontainers/postgresql';

describe('Database tests', () => {
    let container;
    let connectionString;

    beforeAll(async () => {
        container = await new PostgreSqlContainer('postgres:16')
            .withDatabase('testdb')
            .withUsername('test')
            .withPassword('test')
            .start();
        connectionString = container.getConnectionUri();

        // Run migrations
        await runMigrations(connectionString);
    });

    afterAll(async () => {
        await container.stop();
    });

    it('should insert and query orders', async () => {
        const db = connectToDb(connectionString);
        await db.insert('orders', { customer_id: 1, total: 100 });
        const result = await db.query('SELECT * FROM orders');
        expect(result.length).toBe(1);
    });
});
```

```python
# Python
import testcontainers.postgres

def test_database():
    with PostgresContainer("postgres:16") as postgres:
        engine = create_engine(postgres.get_connection_url())
        # Run migrations and tests...
```

### Docker Compose for Local Development
```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: app
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d myapp"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

volumes:
  pgdata:
```

## Chaos Engineering for Databases

### Failure Scenarios to Test

| Scenario | Tool | What It Tests |
|----------|------|--------------|
| **Kill primary** | `docker stop`, `kill -9` | Failover speed, data loss (RPO) |
| **Network partition** | `tc`, Toxiproxy, Pumba | Split-brain handling, quorum |
| **Slow I/O** | `tc netem`, Toxiproxy | Query timeouts, connection handling |
| **Disk full** | `fallocate` | Graceful degradation, alerting |
| **High latency** | Toxiproxy | Application timeout handling |
| **CPU saturation** | `stress-ng` | Priority scheduling, query timeout |

### Toxiproxy for Database Testing
```bash
# Create toxic proxy for PostgreSQL
toxiproxy-cli create postgres_proxy -l 0.0.0.0:5433 -u postgres-primary:5432

# Add 500ms latency
toxiproxy-cli toxic add postgres_proxy -t latency -a latency=500 -a jitter=100

# Simulate connection reset
toxiproxy-cli toxic add postgres_proxy -t reset_peer -a timeout=5000

# Remove toxic
toxiproxy-cli toxic remove postgres_proxy -n latency_downstream
```

## GitOps for Database Configuration

### Pattern: Configuration as Code
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

## Multi-Environment Management

### Environment Parity
| Concern | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Engine version** | Same | Same | Same |
| **Schema** | Same (via migrations) | Same | Same |
| **Data** | Seed data / anonymized | Subset of production | Real data |
| **Instance size** | Minimal | Reduced | Full |
| **HA** | Single instance | Optional | Required |
| **Backup** | None | Daily | Continuous PITR |
| **Monitoring** | Basic | Full | Full + alerting |

### Data Anonymization for Non-Production
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

## Quick Reference

1. **Terraform for provisioning** — all database infrastructure as code
2. **Kubernetes operators for management** — automated failover, backup, scaling
3. **Migrations in CI/CD** — validate, lint, test, then apply
4. **Testcontainers for testing** — real database in CI, not mocks
5. **Chaos engineering** — test failover before it happens in production
6. **Environment parity** — same engine version and schema everywhere
7. **Anonymize data** — never use real PII in non-production
