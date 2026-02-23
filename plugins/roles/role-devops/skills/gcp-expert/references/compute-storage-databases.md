# GCP Compute, Storage, and Databases

## When to load
Load when working with GKE, Cloud Run, Cloud Functions, Cloud Storage, Cloud SQL, Cloud Spanner,
Bigtable, BigQuery, Pub/Sub, Artifact Registry, or Cloud Build.

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
- Monitor **CPU utilization** and keep it below 65% for smooth autoscaling headroom.

### Bigtable and BigQuery
- Use Bigtable for time-series data, analytics, IoT, and high-throughput low-latency key-value workloads at petabyte scale.
- Design row keys with access patterns in mind. Prefix row keys by time bucket (reverse timestamp) or hash to distribute writes evenly.
- Use **column families** to group related columns. Garbage-collect old data with column family TTL settings.
- Use **multi-cluster replication** for high availability and cross-region reads.
- Use BigQuery for data warehousing, analytics, and large-scale SQL queries. Serverless — no infrastructure to manage.
- Partition tables by date/timestamp and cluster by high-cardinality filter columns to reduce bytes scanned and control costs.
- Use **BigQuery authorized views** and **row-level security** for fine-grained data access control.
- Enable **BigQuery Reservations** (slot commitments) for predictable analytics workloads.

## Messaging

### Pub/Sub
- Use **Pub/Sub** for global, durable, at-least-once message delivery. Pub/Sub scales automatically with no capacity planning.
- Set **message retention** on subscriptions (up to 7 days) and topics to replay messages during incident recovery.
- Use **dead letter topics** on subscriptions to capture messages that fail delivery after `maxDeliveryAttempts`.
- Use **Pub/Sub push subscriptions** for Cloud Run and Cloud Functions triggers. Use **pull subscriptions** for batch consumers that control read rate.
- Use **Eventarc** (built on Pub/Sub) for routing GCP system events (Audit Logs, Cloud Storage, Artifact Registry) to Cloud Run, Cloud Functions, and GKE.

## CI/CD and Artifact Management

### Cloud Build and Artifact Registry
- Use **Cloud Build** for GCP-native CI/CD. Cloud Build runs on managed, ephemeral workers — no infra to maintain.
- Use **private pools** for builds that need VPC access (Cloud SQL, Artifact Registry via Private IP, internal services).
- Use **Cloud Build service accounts** with minimum required permissions. Avoid the default Cloud Build service account with broad permissions.
- Use **Artifact Registry** as the single registry for Docker images, Maven, npm, Python, Helm charts, and language packages.
- Enable **vulnerability scanning** on Docker repositories. Set deployment policies to block images with critical CVEs.
- Use **Artifact Registry cleanup policies** to automatically delete untagged images or images older than a defined period.
