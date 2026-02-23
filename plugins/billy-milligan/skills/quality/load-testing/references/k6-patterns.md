# k6 Load Testing Patterns

## When to load
Load when writing k6 scripts: scenarios, thresholds, load profiles, custom metrics.

## Basic Script Structure

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 VUs
    { duration: '5m', target: 50 },   // Hold at 50 VUs
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],  // 95th < 500ms
    http_req_failed: ['rate<0.01'],                    // <1% errors
    checks: ['rate>0.99'],                              // 99% checks pass
  },
};

export default function () {
  const res = http.get('https://api.example.com/orders');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has orders array': (r) => JSON.parse(r.body).orders !== undefined,
  });

  sleep(1); // Think time between requests
}
```

## Scenario Types

```javascript
export const options = {
  scenarios: {
    // Constant load
    steady_state: {
      executor: 'constant-arrival-rate',
      rate: 100,            // 100 RPS
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 50,
    },
    // Spike test
    spike: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '10s', target: 500 },  // Spike to 500 RPS
        { duration: '2m', target: 500 },
        { duration: '10s', target: 10 },   // Drop back
      ],
      preAllocatedVUs: 200,
    },
    // Soak test
    soak: {
      executor: 'constant-vus',
      vus: 20,
      duration: '4h',       // 4 hours to find memory leaks
    },
  },
};
```

## Authentication

```javascript
import http from 'k6/http';

export function setup() {
  const res = http.post('https://api.example.com/auth/login', JSON.stringify({
    email: 'loadtest@example.com',
    password: __ENV.TEST_PASSWORD,
  }), { headers: { 'Content-Type': 'application/json' } });

  return { token: JSON.parse(res.body).accessToken };
}

export default function (data) {
  http.get('https://api.example.com/orders', {
    headers: { Authorization: `Bearer ${data.token}` },
  });
}
```

## Anti-patterns
- No think time (sleep) → unrealistic traffic pattern
- Testing from same machine as target → network/CPU contention
- Fixed VU count instead of arrival rate → doesn't test real RPS
- No thresholds → test passes even with 50% errors

## Quick reference
```
Ramp-up: 2 min to target VUs
Thresholds: p95<500ms, p99<1000ms, errors<1%
Scenarios: constant-arrival-rate for RPS, ramping for spike
Soak: 4h+ at moderate load to find leaks
Think time: sleep(1) between requests
Auth: setup() function runs once, shares token
Run: k6 run --env TEST_PASSWORD=xxx script.js
Cloud: k6 cloud run script.js for distributed load
```
