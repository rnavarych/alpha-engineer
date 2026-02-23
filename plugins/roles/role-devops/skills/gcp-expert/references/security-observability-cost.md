# GCP Security, Observability, and Cost Optimization

## When to load
Load when working with Security Command Center, Cloud Armor, Cloud KMS, Secret Manager,
Cloud Logging/Monitoring/Trace, SLO monitoring, or Committed Use Discounts and billing exports.

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

## Observability (Cloud Operations)

- Use **Cloud Logging** for centralized log management. Route logs to Cloud Storage (long-term retention), BigQuery (analysis), or Pub/Sub (SIEM integration) via log sinks.
- Apply **log exclusion filters** to reduce log volume from noisy, low-value sources (health check requests, verbose debug logs) before they incur storage costs.
- Use **Cloud Monitoring** for metrics, uptime checks, alerting, and dashboards. Create **alerting policies** based on MQL (Monitoring Query Language) for complex, multi-condition alerts.
- Use **SLO monitoring** in Cloud Monitoring natively — define request-based or window-based SLOs and alert on error budget burn rate.
- Use **Cloud Trace** for distributed tracing. Integrate via OpenTelemetry OTLP. Use sampling rates appropriate for production traffic volume.
- Use **Cloud Profiler** for continuous CPU and heap profiling of production services with minimal overhead.
- Use **Cloud Error Reporting** for automatic exception detection, grouping, and alerting from Cloud Logging.

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
