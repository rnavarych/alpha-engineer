# Artillery Load Testing

## When to load
Load when using Artillery for load testing: YAML config, phases, custom functions, cloud.

## Config Structure

```yaml
# artillery.yml
config:
  target: "https://api.example.com"
  phases:
    - duration: 120    # 2 min warm-up
      arrivalRate: 5
      name: "Warm up"
    - duration: 300    # 5 min sustained load
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60     # 1 min spike
      arrivalRate: 200
      name: "Spike"
  defaults:
    headers:
      Content-Type: "application/json"
  ensure:
    thresholds:
      - http.response_time.p95: 500   # p95 < 500ms
      - http.response_time.p99: 1000
      - http.codes.500: 0             # Zero 500 errors

scenarios:
  - name: "Browse and order"
    weight: 70    # 70% of virtual users
    flow:
      - get:
          url: "/api/products"
          capture:
            - json: "$.products[0].id"
              as: "productId"
      - think: 2
      - post:
          url: "/api/orders"
          json:
            items:
              - productId: "{{ productId }}"
                quantity: 1
          expect:
            - statusCode: 201

  - name: "Just browsing"
    weight: 30
    flow:
      - get:
          url: "/api/products"
      - think: 3
      - get:
          url: "/api/products/{{ productId }}"
```

## Custom Functions

```javascript
// functions.js
module.exports = {
  generateUser: (context, events, done) => {
    context.vars.email = `user${Date.now()}@loadtest.com`;
    context.vars.password = 'Test1234!';
    return done();
  },

  logResponse: (req, res, context, events, done) => {
    if (res.statusCode >= 400) {
      console.log(`Error ${res.statusCode}: ${res.body}`);
    }
    return done();
  },
};
```

## Run Commands

```bash
# Local run
artillery run artillery.yml

# With environment variables
artillery run -e staging artillery.yml

# Generate HTML report
artillery run --output report.json artillery.yml
artillery report report.json --output report.html

# Cloud distributed run (Artillery Pro)
artillery run --platform-opt-in artillery.yml
```

## Anti-patterns
- No `think` time between requests → unrealistic burst patterns
- Missing `ensure` thresholds → test always "passes"
- Hardcoded auth tokens → expire during long tests
- Testing from single region → doesn't reflect real geographic distribution

## Quick reference
```
Phases: warm-up (low) → sustained (target) → spike (peak)
Weight: distribute traffic across scenarios (70/30)
Capture: extract values from responses for later use
Think: pause between requests (simulates user)
Ensure: fail test if thresholds exceeded
Report: --output report.json → artillery report
```
