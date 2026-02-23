# API Testing Tools and Patterns

## When to load
When writing SuperTest, REST Assured, or httpx tests; when setting up Postman/Newman in CI; when implementing contract testing with Pact; when configuring mock servers (WireMock, MSW).

## Tool Selection

| Tool | Language | Best For |
|------|----------|----------|
| **SuperTest** | Node.js | Express/Fastify integration tests |
| **REST Assured** | Java | Enterprise Java API testing |
| **httpx / requests** | Python | Django/Flask/FastAPI testing |
| **Postman / Newman** | Any | Manual exploration + CI collection execution |

## SuperTest Pattern
```typescript
describe('POST /api/users', () => {
  it('should create a user with valid data', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', name: 'Test User' })
      .expect(201);
    expect(res.body).toMatchObject({ id: expect.any(String), email: 'test@example.com' });
  });
});
```

## Contract Testing (Pact)

1. **Consumer**: Define expected interactions (request/response pairs).
2. **Generate**: Pact test creates a contract file.
3. **Provider**: Replay contract against real provider and verify.
4. **Broker**: Share contracts between teams. Prevent deployments with broken contracts.

## Schema Validation

- Validate responses against JSON Schema or OpenAPI spec automatically in tests.
- Use `schemathesis` for specification-based fuzzing from the OpenAPI spec.
- Generate test cases to cover all documented endpoints and response codes.

## Mock Servers

- **WireMock**: Stub external APIs. Record/replay real traffic. Simulate errors and timeouts.
- **MSW**: Network-level request interception for JavaScript. No code changes needed.

```typescript
const server = setupServer(
  http.get('/api/users/:id', ({ params }) =>
    HttpResponse.json({ id: params.id, name: 'Mock User' })
  )
);
```

## Auth Token Management

- Use a test helper to obtain tokens. Never hardcode tokens in test files.
- Create separate test users with scoped permissions per scenario.
- Use environment variables for credentials. Never commit to source control.

## API Performance Baselines

- Measure P50, P95, P99 response times for critical endpoints.
- Set CI thresholds: fail if P95 exceeds baseline by >20%.
- Test with realistic payload sizes, not just minimal test data.
