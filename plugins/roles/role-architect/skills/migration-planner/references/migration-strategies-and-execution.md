# Migration Strategies, Data Migration, and Zero-Downtime Techniques

## When to load
Load when planning a system migration using strangler fig or parallel run patterns, designing ETL/CDC/dual-write data migration, tracking feature parity, or implementing zero-downtime techniques (blue-green, rolling, expand-and-contract).

## Strangler Fig Pattern

- Incrementally replace a legacy system by routing traffic to the new system feature by feature, while the legacy system continues to serve unreplaced features.
- Implementation: place a facade (API gateway, reverse proxy, or routing layer) in front of both systems. Route specific endpoints or features to the new system as they are built and validated.
- Start with low-risk, high-value features. Each migrated feature proves the new system's viability and builds team confidence.
- The legacy system shrinks over time until it handles no traffic and can be decommissioned.
- Key risk: the facade becomes a bottleneck or single point of failure. Design it for high availability and low latency.

## Parallel Run Strategy

- Run both the old and new systems simultaneously, processing the same inputs and comparing outputs.
- Shadow mode: route all traffic to the legacy system (source of truth) and mirror traffic to the new system. Compare results offline. No user impact.
- Dark launching: the new system processes real traffic but its results are not shown to users. Validate correctness and performance under real load.
- Graduated cutover: start routing a small percentage of traffic (1%, 5%, 10%) to the new system. Monitor error rates, latency, and correctness. Increase percentage as confidence grows.
- Parallel runs are expensive (double infrastructure) but provide the highest confidence for critical systems.

## Data Migration

### ETL (Extract, Transform, Load)
- Batch migration of historical data. Extract from legacy, transform to new schema, load into new system.
- Run during maintenance windows or off-peak hours. Validate row counts, checksums, and business rule invariants after loading.
- For large datasets, use incremental ETL: migrate data in chunks ordered by a timestamp or sequence number.

### Change Data Capture (CDC)
- Stream real-time changes from the legacy database to the new system using database log readers (Debezium, DMS, Fivetran).
- Enables continuous synchronization during the migration period. No maintenance window required.
- Handle schema differences with transformation logic in the CDC pipeline.
- Monitor lag between source and target. Alert if lag exceeds acceptable thresholds.

### Dual-Write
- Application writes to both the old and new systems on every operation.
- Pros: both systems stay in sync in real time.
- Cons: write latency increases, consistency is harder (what if one write succeeds and the other fails?), and application code becomes more complex.
- Use dual-write only for short migration windows. Prefer CDC for longer transitions.
- Implement a reconciliation job that compares both systems periodically and reports discrepancies.

## Feature Parity Tracking

- Maintain a feature parity matrix: list every feature of the legacy system and its status in the new system (not started, in progress, complete, intentionally omitted).
- Classify features: must-have (blocking migration), nice-to-have (migrate after cutover), and deprecated (do not migrate).
- Track parity at the API level: every legacy endpoint must have a corresponding new endpoint with equivalent behavior.
- Automate parity testing: run the same test suite against both systems and compare results.

## Phased Timelines

- Break the migration into phases with clear milestones and success criteria:
  - **Phase 0**: Foundation. Set up the new system, deploy infrastructure, establish CI/CD, build the routing facade.
  - **Phase 1**: First feature. Migrate one low-risk feature end-to-end. Validate the entire pipeline.
  - **Phase 2**: Core features. Migrate high-value features in priority order. Parallel run where possible.
  - **Phase 3**: Long tail. Migrate remaining features. Address edge cases and legacy integrations.
  - **Phase 4**: Decommission. Remove the legacy system after a stability period (typically 2-4 weeks of zero legacy traffic).
- Each phase should be independently deployable and rollbackable. Never combine multiple risky changes in one phase.

## Zero-Downtime Migration Techniques

- **Blue-green deployment**: provision the new system alongside the old. Switch traffic atomically at the load balancer. Rollback by switching back.
- **Rolling deployment**: update instances one at a time. Each instance is taken out of the load balancer, updated, validated, and returned. No capacity reduction if spare capacity exists.
- **Database schema migration without downtime**: use expand-and-contract pattern. Add new columns/tables first (expand), deploy code that writes to both old and new schema, migrate existing data, deploy code that reads only from new schema, drop old columns/tables (contract).
- **API versioning**: maintain both old and new API versions during migration. Deprecate the old version after all clients have migrated.
- **Feature flags**: wrap new behavior behind feature flags. Enable gradually per user segment, per region, or per percentage. Disable instantly if issues arise.
