---
name: gcp-patterns
description: |
  GCP production patterns: Cloud Run with Terraform, Workload Identity Federation (no service
  account keys), Cloud SQL with private IP, Memorystore Redis, BigQuery for analytics,
  Cloud Armor WAF, Secret Manager, VPC Service Controls, IAM least privilege bindings.
  Use when designing GCP architecture, writing Terraform for GCP, reviewing IAM policies.
allowed-tools: Read, Grep, Glob
---

# GCP Production Patterns

## When to Use This Skill
- Deploying containers to Cloud Run
- Setting up Workload Identity Federation (no SA keys)
- Configuring Cloud SQL with private IP
- Writing Terraform for GCP infrastructure
- Querying BigQuery for analytics

## Core Principles

1. **Cloud Run for stateless services** — autoscales to 0, no cluster management, pay per request
2. **Workload Identity Federation, never SA keys** — SA keys are persistent credentials; WIF is token-based and short-lived
3. **Private IP for all data services** — Cloud SQL, Memorystore: no public IP, accessed via VPC
4. **IAM bindings on resources, not members** — bind roles to service accounts scoped to specific resources
5. **BigQuery for analytics over Cloud SQL** — even 1B row aggregations run in <10 seconds on BigQuery

---

## Patterns ✅

### Cloud Run Service (Terraform)

```hcl
resource "google_cloud_run_v2_service" "order_service" {
  name     = "order-service"
  location = "us-central1"

  template {
    service_account = google_service_account.order_service.email

    scaling {
      min_instance_count = 2   # Always warm — no cold starts for production
      max_instance_count = 20
    }

    containers {
      image = "gcr.io/${var.project_id}/order-service:${var.image_tag}"

      resources {
        limits = {
          cpu    = "1"      # 1 vCPU
          memory = "512Mi"
        }
        cpu_idle = false  # CPU always allocated (not just during requests)
      }

      ports {
        container_port = 3000
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_url.secret_id
            version = "latest"
          }
        }
      }

      startup_probe {
        http_get {
          path = "/health/startup"
          port = 3000
        }
        initial_delay_seconds = 10
        failure_threshold     = 10
        period_seconds        = 5
      }

      liveness_probe {
        http_get {
          path = "/health/live"
          port = 3000
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.main.id
      egress    = "PRIVATE_RANGES_ONLY"  # Only route private IP traffic through VPC
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Allow unauthenticated access (for public API)
resource "google_cloud_run_v2_service_iam_binding" "public" {
  name     = google_cloud_run_v2_service.order_service.name
  location = google_cloud_run_v2_service.order_service.location
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}
```

### Workload Identity Federation (GitHub Actions — No SA Keys)

```hcl
# Create Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == 'myorg/myrepo'"  # Restrict to one repo
}

# Allow GitHub Actions to impersonate the deploy service account
resource "google_service_account_iam_binding" "github_deploy" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/myorg/myrepo"
  ]
}
```

```yaml
# GitHub Actions workflow using Workload Identity
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: "projects/123456/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
    service_account: "deploy@myproject.iam.gserviceaccount.com"
    # No SA key JSON — short-lived OIDC token exchange
```

### Cloud SQL with Private IP

```hcl
resource "google_sql_database_instance" "postgres" {
  name             = "production-postgres"
  database_version = "POSTGRES_16"
  region           = "us-central1"

  settings {
    tier              = "db-g1-small"   # 1.7GB RAM, 1 shared vCPU
    availability_type = "REGIONAL"      # Multi-zone HA (like Multi-AZ in AWS)
    disk_autoresize   = true
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false           # No public IP
      private_network = google_compute_network.main.self_link
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true    # PITR for precise recovery
      backup_retention_settings {
        retained_backups = 7
      }
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }
    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"  # Log queries slower than 1000ms
    }
  }

  deletion_protection = true
}
```

### BigQuery for Analytics

```sql
-- BigQuery: partition by date, cluster by common filter columns
-- Reduces bytes scanned dramatically (billing is per byte scanned)

CREATE TABLE `myproject.analytics.order_events`
(
  event_id    STRING,
  event_type  STRING,
  user_id     STRING,
  order_id    STRING,
  amount      FLOAT64,
  currency    STRING,
  created_at  TIMESTAMP
)
PARTITION BY DATE(created_at)          -- Partitioning: only scans relevant date partitions
CLUSTER BY event_type, user_id;        -- Clustering: co-locate related data
-- 90-day query on 500M rows: 2.3s, scans ~4GB (not 500GB)

-- Stream events from Cloud Run via Pub/Sub → BigQuery subscription (no ETL code)
-- Or direct insert:
INSERT INTO `myproject.analytics.order_events`
SELECT
  GENERATE_UUID() AS event_id,
  'order_placed' AS event_type,
  user_id,
  order_id,
  total AS amount,
  currency,
  CURRENT_TIMESTAMP() AS created_at
FROM orders
WHERE created_at > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);
```

### IAM Least Privilege on Resources

```hcl
# Service account for order-service
resource "google_service_account" "order_service" {
  account_id   = "order-service"
  display_name = "Order Service"
}

# Cloud SQL client — only connects, doesn't administer
resource "google_project_iam_binding" "order_service_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  members = ["serviceAccount:${google_service_account.order_service.email}"]
}

# Secret Manager — only read specific secrets
resource "google_secret_manager_secret_iam_binding" "db_url" {
  secret_id = google_secret_manager_secret.db_url.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members   = ["serviceAccount:${google_service_account.order_service.email}"]
  # Scoped to specific secret — not all secrets in the project
}

# Pub/Sub — only publish to specific topic
resource "google_pubsub_topic_iam_binding" "order_events" {
  topic   = google_pubsub_topic.order_events.name
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.order_service.email}"]
}
```

---

## Anti-Patterns ❌

### Service Account Keys in Repository
**What it is**: `gcloud iam service-accounts keys create key.json` and storing in repo or CI secrets.
**What breaks**: Key exposed in git history or log = persistent attacker access. Key doesn't auto-expire.
**Fix**: Workload Identity Federation. Short-lived OIDC tokens, no persistent credentials.

### Cloud SQL with Public IP
**What it is**: `ipv4_enabled = true` with Cloud SQL Auth Proxy or authorized networks.
**What breaks**: Database surface on public internet. Auth Proxy helps but public IP is still unnecessary exposure.
**Fix**: `ipv4_enabled = false`. Private IP only. Access via VPC from Cloud Run/GKE.

### Owner/Editor Role on Service Account
**What it is**: `roles/editor` or `roles/owner` on the service account used by Cloud Run.
**What breaks**: Compromised app has full project access — can read all data, create resources, delete backups.
**Fix**: Specific roles scoped to specific resources. Cloud Run SA needs `cloudsql.client` + specific secrets, nothing else.

---

## Quick Reference

```
Cloud Run: min_instance_count=2 for production (avoid cold starts)
WIF: Workload Identity Federation for CI/CD — never SA key files
Cloud SQL: ipv4_enabled=false, REGIONAL availability, PITR enabled
BigQuery: PARTITION BY DATE + CLUSTER BY to reduce scanned bytes
IAM: bind roles to specific resources (secrets, topics) not project-wide
Memorystore: Redis in same VPC, no public IP
Secret Manager vs env vars: use Secret Manager for passwords/keys
Cloud Armor: WAF in front of load balancer for DDoS/OWASP rules
VPC Connector: required for Cloud Run to reach private IP resources
Artifact Registry: store Docker images (not Docker Hub) for speed + security
```
