# Performance Testing Tools and Test Types

## When to load
When selecting a performance testing tool (k6, JMeter, Gatling, Artillery); when designing load, stress, soak, or spike test scenarios; when configuring thresholds for CI gates.

## Test Types

| Type | Purpose | Pattern |
|------|---------|---------|
| **Load test** | Validate expected traffic | Ramp to target RPS, hold steady, measure latency |
| **Stress test** | Find breaking point | Ramp beyond expected load until errors appear |
| **Soak test** | Detect memory leaks | Sustained moderate load for 2-8 hours |
| **Spike test** | Validate autoscaling | Sudden burst then drop to normal |

## k6 (Recommended)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('https://api.example.com/products');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```
- Define `thresholds` to enforce pass/fail in CI. Use `scenarios` for complex traffic patterns.
- Export results to Grafana/InfluxDB for dashboards.
- Use `k6 cloud` for multi-region distributed execution.

## Custom Metrics
```javascript
import { Trend, Counter } from 'k6/metrics';
const orderLatency = new Trend('order_creation_latency');
```
- Define business-relevant metrics (order creation, payment processing latency).
- Track alongside standard HTTP metrics for complete visibility into user-impacting paths.

## Other Tools

- **JMeter**: GUI-based test plans, large-scale distributed testing. CLI execution: `jmeter -n -t test.jmx -l results.jtl`.
- **Gatling**: Scala DSL, excellent HTML reports. `setUp(scn.inject(rampUsers(100).during(60)))`.
- **Artillery**: YAML config, low barrier to entry. Plugin ecosystem covers WebSocket, gRPC, and Kafka.
