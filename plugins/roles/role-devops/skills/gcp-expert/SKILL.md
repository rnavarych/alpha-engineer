---
name: gcp-expert
description: |
  Deep Google Cloud Platform expertise covering IAM and Workload Identity,
  VPC networking, GKE, Cloud Run, Cloud SQL and Spanner, Bigtable, Cloud Storage,
  BigQuery, Pub/Sub, Cloud CDN, Cloud Armor, Cloud Load Balancing, Cloud DNS,
  Logging and Monitoring, Secret Manager, Cloud KMS, Security Command Center,
  Artifact Registry, Cloud Build, and Committed Use Discounts for production GCP workloads.
allowed-tools: Read, Grep, Glob, Bash
---

# GCP Expert

## IAM and Identity

### Resource Hierarchy and IAM Model
- GCP uses a **resource hierarchy**: Organization → Folders → Projects → Resources. IAM policies are inherited downward — policies set at the Organization or Folder level propagate to all child resources.
- Organize with **Folders** by environment (production, staging, development) or by business unit. Apply IAM and Organization Policies at the Folder level to enforce environment boundaries.
- Grant IAM roles at the **lowest level** of the hierarchy that satisfies the use case. Prefer project-level or resource-level roles over folder/organization-level where practical.
- Use **predefined roles** over primitive roles (`roles/owner`, `roles/editor`, `roles/viewer`). Primitive roles are too broad; predefined roles (e.g., `roles/compute.instanceAdmin.v1`) follow least privilege.
- Use **custom IAM roles** when predefined roles are too permissive — combine specific permissions into a narrowly scoped role.
- Enforce **Organization Policy constraints** for preventive guardrails: `constraints/iam.disableServiceAccountKeyCreation`, `constraints/compute.requireShieldedVm`, `constraints/gcp.resourceLocations` to restrict which regions resources can be created in.

### Workload Identity Federation
- **Workload Identity Federation** allows external workloads (GitHub Actions, GitLab CI, AWS workloads, on-premises) to impersonate GCP Service Accounts without JSON key files.
- Configure an OIDC or SAML identity pool, bind the external identity to a service account with `roles/iam.workloadIdentityUser`.
- For GitHub Actions: use the `google-github-actions/auth` action with Workload Identity Federation — zero static credentials in GitHub Secrets.
- **Workload Identity for GKE** (not the same as federation): bind Kubernetes ServiceAccounts to GCP Service Accounts via annotation. Pods receive auto-refreshed GCP credentials via the metadata server.

### Service Accounts Best Practices
- One Service Account per workload, per environment. Never reuse service accounts across services.
- Avoid **JSON key files** entirely for compute workloads. Use attached service accounts for GCE/GKE, Cloud Build, and Cloud Run.
- Rotate and revoke unused service account keys. Use **Security Command Center** findings to detect overprivileged or unused service accounts.
- Apply **Service Account resource policies** to restrict which identities can impersonate a service account.

---

## Networking (VPC)

### VPC Design
- GCP VPCs are **global** — a single VPC spans all regions. Subnets are regional. This simplifies connectivity compared to AWS's per-region VPC model.
- Use **Shared VPC** (a host project's VPC shared to service projects) to centralize networking management. Network team owns the host project; application teams deploy into service projects with shared subnets.
- Design subnet IP ranges for growth. GKE uses alias IP ranges for pod IPs — size subnets accordingly (`/20` secondary range per node pool supports up to 4096 pods).
- Use **Private Google Access** on subnets so VMs without external IPs can reach Google APIs (GCS, BigQuery, etc.) via private routes.
- Use **VPC Service Controls** to create security perimeters around sensitive GCP services (BigQuery, GCS, Spanner) — prevents data exfiltration even by compromised identities.
- Use **Cloud NAT** for outbound internet access from private VMs without assigning external IPs.

### Cloud Load Balancing
- **Global External Application Load Balancer (HTTP/HTTPS)**: anycast IP, global routing to nearest healthy backend, Cloud CDN integration, Cloud Armor WAF, URL map-based routing.
- **Regional External Application Load Balancer**: regional scope, same feature set for region-specific requirements.
- **Internal Application Load Balancer**: for private traffic between GCP services. Supports Envoy-based traffic management (traffic mirroring, fault injection, circuit breaking).
- **Network Load Balancer (passthrough)**: TCP/UDP, preserves client IPs, low latency. Use when the application needs the original client IP or handles raw TCP.
- **Cloud CDN**: Enable on HTTPS LB backends for static and dynamic content caching. Use cache keys and cache invalidation APIs for controlled purging.
- Use **Backend Services** health checks with appropriate thresholds — avoid triggering failover on brief transient failures.

### Cloud DNS and Traffic Management
- Use **Cloud DNS private zones** for internal DNS resolution within VPC networks. Use **DNS peering** to share private zones across peered networks.
- Use **Cloud DNS routing policies** for weighted round-robin (canary traffic splits) and geolocation-based routing.
- Use **Traffic Director** (GCP's service mesh control plane) for Envoy-based load balancing, traffic splitting, and health management across hybrid environments without per-pod sidecars.

---

## Compute

### GKE (Google Kubernetes Engine)
- Use **GKE Autopilot** for managed, serverless Kubernetes where GCP manages nodes, scaling, and security configuration. Billing per pod resource request.
- Use **GKE Standard** for full control over node configuration: custom node pools, specialized hardware (GPUs, TPUs), specific OS images.
- Enable **Workload Identity** on all GKE clusters. Disable legacy metadata server access (`--workload-metadata=GKE_METADATA`).
- Use **Shielded GKE Nodes** with Secure Boot, vTPM, and Integrity Monitoring enabled.
- Use **GKE node auto-provisioning (NAP)** for dynamic node pool creation, or configure manual node pools for predictable workloads.
- Enable **Binary Authorization** to enforce that only signed, approved container images are deployed to production clusters.
- Use **GKE Gateway API** (managed Envoy-based) for advanced traffic management from within the cluster.
- Enable **GKE Dataplane V2** (eBPF-based via Cilium) for network policy enforcement and enhanced observability.
- Use **GKE Release Channels** (Regular, Stable, Rapid) for automated Kubernetes version upgrades with appropriate stability guarantees.
- Enable **GKE Sandbox (gVisor)** for untrusted workloads requiring strong container isolation.

### Cloud Run
- **Cloud Run** for serverless containers — fully managed, scales to zero, per-100ms billing.
- Use **Cloud Run services** for request-driven workloads (APIs, webhooks). Use **Cloud Run jobs** for batch and scheduled tasks.
- Enable **VPC Connector** or **Direct VPC Egress** so Cloud Run services can access private VPC resources (Cloud SQL, Redis, internal services).
- Use **Cloud Run IAM invoker roles** to restrict which identities can invoke services. Never expose services publicly without auth unless required.
- Set **concurrency** (requests per container instance) and **min instances** (to eliminate cold starts for latency-sensitive services).
- Use **Cloud Run with Artifact Registry** for secure image pulls — no public Docker Hub dependencies.

### Cloud Functions (Gen 2)
- **Gen 2 Cloud Functions** run on Cloud Run under the hood — benefits include longer timeouts (60 min), larger instances, concurrent requests.
- Use **eventarc triggers** for event-driven functions (Pub/Sub, Audit Log events, Cloud Storage events).
- Apply **minimum instances** for latency-sensitive functions to avoid cold starts.

---

## Storage and Databases

### Cloud Storage (GCS)
- Use **uniform bucket-level access** (disable ACLs) and control access exclusively via IAM.
- Apply **retention policies** and **object holds** (WORM) for compliance data that must not be deleted.
- Use **lifecycle rules** to transition objects to cheaper storage classes (Nearline, Coldline, Archive) and delete expired objects.
- Enable **Bucket Lock** to make retention policies immutable once set — required for SEC 17a-4 and similar compliance.
- Use **Signed URLs** for temporary object access without granting permanent IAM permissions.
- Enable **Cloud Storage Pub/Sub notifications** for event-driven processing of new or changed objects.
- Use **Cloud Storage FUSE** to mount buckets as POSIX filesystems on GCE VMs or GKE pods for large-scale data access.

### Cloud SQL
- Use **Cloud SQL High Availability** (HA) configuration for production: synchronous replication to a standby in the same region.
- Use **Private IP** for Cloud SQL instances — never expose instances via public IP. Connect via Private Service Connect or VPC peering.
- Use **Cloud SQL Auth Proxy** for secure, authenticated connections from applications without whitelisting IP ranges.
- Enable **automated backups** and **point-in-time recovery (PITR)**. Test restores regularly.
- Use **read replicas** in the same or cross-region for read scaling and disaster recovery.
- Use **IAM database authentication** for PostgreSQL and MySQL — SSO with GCP identity, no static database passwords.

### Cloud Spanner
- Use Spanner for global, strongly-consistent, relational workloads that exceed Cloud SQL's scale. Spanner provides unlimited horizontal scaling with zero downtime schema changes.
- Design primary keys to avoid hotspots: avoid monotonically increasing integers as leading key components.
- Use **interleaved tables** for parent-child relationships to co-locate related rows for efficient queries.
- Use **Spanner multi-region configurations** for 99.999% availability SLA and global distribution.
- Monitor **CPU utilization** and keep it below 65% for smooth autoscaling headroom. Use Spanner Metrics to identify hotspots.

### Bigtable
- Use Bigtable for time-series data, analytics, IoT, and high-throughput low-latency key-value workloads at petabyte scale.
- Design row keys with access patterns in mind. Prefix row keys by time bucket (reverse timestamp) or hash to distribute writes evenly.
- Use **column families** to group related columns. Garbage-collect old data with column family TTL settings.
- Use **multi-cluster replication** for high availability and cross-region reads.

### BigQuery
- Use BigQuery for data warehousing, analytics, and large-scale SQL queries. Serverless — no infrastructure to manage.
- Partition tables by date/timestamp and cluster by high-cardinality filter columns to reduce bytes scanned and control costs.
- Use **BigQuery authorized views** and **row-level security** for fine-grained data access control.
- Enable **BigQuery Reservations** (slot commitments) for predictable analytics workloads. Use on-demand pricing for sporadic queries.
- Use **BigQuery Transfer Service** for automated data loading from GCS, Google Ads, YouTube, and other sources.
- Stream data via **BigQuery Storage Write API** for low-latency exactly-once streaming ingestion.

---

## Messaging

### Pub/Sub
- Use **Pub/Sub** for global, durable, at-least-once message delivery. Pub/Sub scales automatically with no capacity planning.
- Set **message retention** on subscriptions (up to 7 days) and topics to replay messages during incident recovery.
- Use **Pub/Sub Lite** for cost-optimized, zonal or regional message streaming when global distribution is not required.
- Use **dead letter topics** on subscriptions to capture messages that fail delivery after `maxDeliveryAttempts`.
- Use **Pub/Sub push subscriptions** for Cloud Run and Cloud Functions triggers. Use **pull subscriptions** for batch consumers that control read rate.
- Use **Eventarc** (built on Pub/Sub) for routing GCP system events (Audit Logs, Cloud Storage, Artifact Registry) to Cloud Run, Cloud Functions, and GKE.

---

## Security

### Security Command Center (SCC)
- Enable **SCC Standard** at the organization level for asset inventory, misconfigurations, and vulnerability findings across all projects.
- Enable **SCC Premium** for advanced threat detection, container threat detection, Event Threat Detection, and compliance dashboards (CIS, PCI DSS, HIPAA).
- Integrate SCC findings with **Cloud Logging** and **Pub/Sub** to feed into SIEM (Chronicle, Splunk) for centralized alerting.

### Cloud Armor (WAF and DDoS)
- Attach **Cloud Armor** policies to Global External Application Load Balancers for WAF rules and DDoS protection.
- Use the **Managed Protection Plus** subscription for adaptive protection (ML-based attack detection) and named IP lists (Tor exit nodes, known bad actors).
- Define **rate limiting rules** to throttle abusive clients per IP before they reach backends.
- Use **preview mode** for new rules before switching to `enforce` to validate rule behavior against production traffic.

### Cloud KMS and Secret Manager
- Use **Cloud KMS** for envelope encryption of data at rest. Create keys per service per data classification level.
- Use **KMS key rotation** (automatic) on a 90-day schedule for active keys.
- Use **Cloud HSM** for FIPS 140-2 Level 3 key protection for regulated industries.
- Use **Secret Manager** for application secrets — API keys, database passwords, certificates. Access via SDK or Secret Manager sidecar.
- Use **Secret Manager versions** and set older versions to `DISABLED` after rotation rather than deleting them immediately.
- Enable **Secret Manager audit logging** to track every secret access event.

---

## Observability (Cloud Operations)

- Use **Cloud Logging** for centralized log management. Route logs to Cloud Storage (long-term retention), BigQuery (analysis), or Pub/Sub (SIEM integration) via log sinks.
- Apply **log exclusion filters** to reduce log volume from noisy, low-value sources (health check requests, verbose debug logs) before they incur storage costs.
- Use **Cloud Monitoring** for metrics, uptime checks, alerting, and dashboards. Create **alerting policies** based on MQL (Monitoring Query Language) for complex, multi-condition alerts.
- Use **SLO monitoring** in Cloud Monitoring natively — define request-based or window-based SLOs and alert on error budget burn rate.
- Use **Cloud Trace** for distributed tracing. Integrate via OpenTelemetry OTLP. Use sampling rates appropriate for production traffic volume.
- Use **Cloud Profiler** for continuous CPU and heap profiling of production services with minimal overhead.
- Use **Cloud Error Reporting** for automatic exception detection, grouping, and alerting from Cloud Logging.

---

## CI/CD and Artifact Management

### Cloud Build
- Use **Cloud Build** for GCP-native CI/CD. Cloud Build runs on managed, ephemeral workers — no infra to maintain.
- Use **private pools** for builds that need VPC access (Cloud SQL, Artifact Registry via Private IP, internal services).
- Use **Cloud Build triggers** on push, PR, or manual execution. Integrate with GitHub, GitLab, or Bitbucket.
- Use **Cloud Build service accounts** with minimum required permissions. Avoid the default Cloud Build service account with broad permissions.

### Artifact Registry
- Use **Artifact Registry** as the single registry for Docker images, Maven, npm, Python, Helm charts, and language packages.
- Enable **vulnerability scanning** on Docker repositories. Set deployment policies to block images with critical CVEs.
- Use **Artifact Registry CMEK** for customer-managed encryption of stored artifacts.
- Use **Artifact Registry cleanup policies** to automatically delete untagged images or images older than a defined period.

---

## Cost Optimization

### Committed Use Discounts (CUDs)
- Use **Resource-based CUDs** for predictable GCE instance types — up to 57% discount for 1-year, 70% for 3-year commitment.
- Use **Flexible CUDs** (spend-based) for GCE, Cloud SQL, and Cloud Spanner when instance type flexibility is needed across a family.
- Commit to 70-80% of your baseline compute. Scope commitments at the project or billing account level.

### Cost Visibility
- Use **Cloud Billing Export** to BigQuery for granular cost data. Build dashboards in Looker Studio or Grafana for team-level cost visibility.
- Enable **resource-level cost allocation** with labels on every resource (`team`, `environment`, `service`).
- Set up **Budget Alerts** at project and folder levels. Alert at 50%, 90%, 100%, and forecasted overage.
- Use **Recommender API** for right-sizing recommendations on GCE VMs and GKE node pools.
- Use **Committed Use Discount recommendations** from the Billing console to identify optimal commitment opportunities.
- Delete unused Persistent Disks, unattached static IPs, and idle Cloud SQL instances — Recommender surfaces these automatically.

---

## Best Practices Checklist

1. Organization Policy constraints enforced at folder/org level (restrict regions, require Shielded VMs, disable SA keys)
2. Workload Identity for GKE — no JSON key files on clusters
3. Workload Identity Federation for CI/CD — no static service account keys in pipelines
4. Shared VPC with centralized network management
5. VPC Service Controls around sensitive data services
6. Private IP for all Cloud SQL instances with Auth Proxy
7. Binary Authorization enabled on GKE production clusters
8. Cloud Armor WAF attached to all external load balancers
9. SCC enabled at organization level with active findings routed to SIEM
10. Secret Manager for all secrets — no plaintext in environment variables
11. Cloud Logging sinks configured for long-term retention and SIEM integration
12. SLO monitoring with burn rate alerting in Cloud Monitoring
13. Artifact Registry vulnerability scanning with deployment policy gates
14. Committed Use Discounts covering baseline GCE and Cloud SQL
15. Cost allocation labels enforced across all resources with Budget Alerts configured
