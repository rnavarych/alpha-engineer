---
name: contract-testing
description: |
  Contract testing: Pact consumer-driven contracts (provider states, interaction definitions),
  provider verification with state handlers, OpenAPI validation middleware, breaking change
  detection. Use when microservices need integration confidence without full e2e tests.
allowed-tools: Read, Grep, Glob
---

# Contract Testing

## When to Use This Skill
- Building microservices that need integration confidence
- Replacing brittle integration tests with faster contract tests
- Detecting breaking API changes before deployment
- Setting up provider verification in CI

## Core Principles

1. **Consumer drives the contract** — the client defines what it actually needs
2. **Provider verifies against consumer contracts** — not against a human-written spec
3. **Contracts live in Pact Broker** — visible to all teams, tracked over time
4. **State handlers make tests reproducible** — provider sets up data for each interaction
5. **Can-I-Deploy check** — never deploy a provider that breaks a consumer contract

---

## Patterns ✅

### Consumer-Side Pact Test

```typescript
// order-service/src/clients/inventory.pact.test.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { InventoryClient } from './InventoryClient';
import path from 'path';

const { like, integer, string, eachLike } = MatchersV3;

const provider = new PactV3({
  consumer: 'order-service',
  provider: 'inventory-service',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'error',
});

describe('InventoryClient contract', () => {
  describe('checkStock', () => {
    it('should return available quantity for existing product', async () => {
      await provider
        .given('product prod_123 has 50 units in stock')  // Provider state
        .uponReceiving('a request to check stock for prod_123')
        .withRequest({
          method: 'GET',
          path: '/inventory/prod_123',
          headers: { Accept: 'application/json' },
        })
        .willRespondWith({
          status: 200,
          headers: { 'Content-Type': 'application/json' },
          body: {
            productId: like('prod_123'),       // Any string with same type
            available: integer(50),            // Any integer
            reserved: integer(0),
            updatedAt: like('2024-01-15T10:00:00Z'),
          },
        })
        .executeTest(async (mockServer) => {
          const client = new InventoryClient({ baseUrl: mockServer.url });
          const result = await client.checkStock('prod_123');

          expect(result.productId).toBe('prod_123');
          expect(result.available).toBe(50);
        });
    });

    it('should return 404 for non-existent product', async () => {
      await provider
        .given('product prod_unknown does not exist')
        .uponReceiving('a request to check stock for unknown product')
        .withRequest({ method: 'GET', path: '/inventory/prod_unknown' })
        .willRespondWith({
          status: 404,
          body: { error: like({ code: 'NOT_FOUND', message: string('Product not found') }) },
        })
        .executeTest(async (mockServer) => {
          const client = new InventoryClient({ baseUrl: mockServer.url });
          await expect(client.checkStock('prod_unknown')).rejects.toThrow('Product not found');
        });
    });
  });
});
```

### Provider Verification

```typescript
// inventory-service/src/pact.verify.test.ts
import { Verifier } from '@pact-foundation/pact';
import { app } from '../app';
import { db } from '../db';
import path from 'path';

describe('Provider verification', () => {
  it('should satisfy all consumer contracts', async () => {
    const server = app.listen(0);  // Random port
    const port = (server.address() as AddressInfo).port;

    const verifier = new Verifier({
      provider: 'inventory-service',
      providerBaseUrl: `http://localhost:${port}`,

      // Load contracts from Pact Broker or local files
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      publishVerificationResult: process.env.CI === 'true',
      providerVersion: process.env.GIT_SHA,

      // State handlers: set up data for each provider state
      stateHandlers: {
        'product prod_123 has 50 units in stock': async () => {
          await db.inventory.upsert({
            where: { productId: 'prod_123' },
            create: { productId: 'prod_123', available: 50, reserved: 0 },
            update: { available: 50, reserved: 0 },
          });
        },
        'product prod_unknown does not exist': async () => {
          await db.inventory.deleteMany({ where: { productId: 'prod_unknown' } });
        },
      },
    });

    await verifier.verifyProvider();
    server.close();
  });
});
```

### OpenAPI Validation Middleware

```typescript
// Validate all requests and responses against OpenAPI spec
import OpenApiValidator from 'express-openapi-validator';

app.use(
  OpenApiValidator.middleware({
    apiSpec: './openapi.yaml',
    validateRequests: true,
    validateResponses: true,  // Catch contract violations in dev/staging
    validateSecurity: {
      handlers: {
        BearerAuth: async (req, scopes, schema) => {
          // Verify token
          return verifyToken(req.headers.authorization);
        },
      },
    },
  })
);

// Test: verify responses match OpenAPI spec
describe('OpenAPI contract compliance', () => {
  it('GET /orders response matches schema', async () => {
    const response = await request(app)
      .get('/api/orders')
      .set('Authorization', `Bearer ${validToken}`);

    // OpenAPI validator middleware will throw if response doesn't match schema
    expect(response.status).toBe(200);
    expect(response.body.data).toBeArray();
    // Any field not in schema would cause validator to reject it
  });
});
```

### Can-I-Deploy Check in CI

```yaml
# CI: verify before deploying that all consumers are compatible
- name: Can I Deploy?
  run: |
    npx pact-broker can-i-deploy \
      --pacticipant inventory-service \
      --version ${{ github.sha }} \
      --to production \
      --broker-base-url ${{ secrets.PACT_BROKER_URL }} \
      --broker-token ${{ secrets.PACT_BROKER_TOKEN }}
  # Exits 0 if all consumers verified, exits 1 if any consumer would break
```

---

## Anti-Patterns ❌

### Provider-Defined Contracts
**What it is**: API team writes the contract spec, consumers implement against it.
**What breaks**: Providers define more than consumers actually use. Spec says field X exists; consumer only uses fields A, B. Provider removes X → spec needs updating → now what? Consumers don't actually care about X.
**Fix**: Consumers define what they need (Pact). Providers verify they satisfy those needs.

### Contracts Without State Handlers
**What it is**: Contract tests that assume specific database state already exists.
**What breaks**: Tests pass locally, fail in CI because database is empty or has different test data.
**Fix**: State handlers that create exactly the required data for each interaction.

### Testing Everything with Contract Tests
**What it is**: Using contract tests to verify all business logic between services.
**What breaks**: Contract tests verify the API contract (shape, status codes). Business logic errors (wrong calculation, wrong status transition) need different tests.
**Fix**: Contract tests verify API shape. Integration tests verify business flows. Not a replacement.

---

## Quick Reference

```
Consumer: defines interactions → writes Pact tests → publishes to broker
Provider: loads pacts from broker → runs state handlers → verifies each interaction
Provider state: reproducible data setup — each test is independent
Can-I-Deploy: required check before any deploy — no broken consumer contracts
OpenAPI validator: validateResponses: true in dev/staging — catches regressions
Pact Broker: tracks which consumer versions are verified against which provider versions
Contract vs integration test: contract = shape; integration = business flow
```
