# GCP IAM, Networking, and Load Balancing

## When to load
Load when configuring GCP resource hierarchy, IAM roles, Workload Identity Federation, Shared VPC,
VPC Service Controls, Cloud Load Balancing, Cloud DNS, or Cloud NAT.

## IAM and Identity

### Resource Hierarchy and IAM Model
- GCP uses a **resource hierarchy**: Organization → Folders → Projects → Resources. IAM policies are inherited downward — policies set at the Organization or Folder level propagate to all child resources.
- Organize with **Folders** by environment (production, staging, development) or by business unit. Apply IAM and Organization Policies at the Folder level to enforce environment boundaries.
- Grant IAM roles at the **lowest level** of the hierarchy that satisfies the use case. Prefer project-level or resource-level roles over folder/organization-level where practical.
- Use **predefined roles** over primitive roles (`roles/owner`, `roles/editor`, `roles/viewer`). Primitive roles are too broad.
- Use **custom IAM roles** when predefined roles are too permissive — combine specific permissions into a narrowly scoped role.
- Enforce **Organization Policy constraints** for preventive guardrails: `constraints/iam.disableServiceAccountKeyCreation`, `constraints/compute.requireShieldedVm`, `constraints/gcp.resourceLocations` to restrict which regions resources can be created in.

### Workload Identity Federation
- **Workload Identity Federation** allows external workloads (GitHub Actions, GitLab CI, AWS workloads, on-premises) to impersonate GCP Service Accounts without JSON key files.
- Configure an OIDC or SAML identity pool, bind the external identity to a service account with `roles/iam.workloadIdentityUser`.
- For GitHub Actions: use the `google-github-actions/auth` action with Workload Identity Federation — zero static credentials in GitHub Secrets.
- **Workload Identity for GKE**: bind Kubernetes ServiceAccounts to GCP Service Accounts via annotation. Pods receive auto-refreshed GCP credentials via the metadata server.

### Service Accounts Best Practices
- One Service Account per workload, per environment. Never reuse service accounts across services.
- Avoid **JSON key files** entirely for compute workloads. Use attached service accounts for GCE/GKE, Cloud Build, and Cloud Run.
- Rotate and revoke unused service account keys. Use **Security Command Center** findings to detect overprivileged or unused service accounts.
- Apply **Service Account resource policies** to restrict which identities can impersonate a service account.

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
