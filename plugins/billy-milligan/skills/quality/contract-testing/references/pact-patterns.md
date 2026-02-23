# Pact Contract Testing

## When to load
Load when implementing consumer-driven contracts: Pact tests, provider verification, broker.

## Consumer Test

```typescript
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
const { like, eachLike, regex } = MatchersV3;

const provider = new PactV3({
  consumer: 'OrdersUI',
  provider: 'OrdersAPI',
});

describe('Orders API contract', () => {
  it('returns orders list', async () => {
    await provider
      .given('user has orders')
      .uponReceiving('a request for orders')
      .withRequest({ method: 'GET', path: '/api/orders', headers: { Authorization: regex(/Bearer .+/, 'Bearer token123') } })
      .willRespondWith({
        status: 200,
        body: eachLike({
          id: like('order-1'),
          total: like(4999),
          status: regex(/pending|completed|cancelled/, 'pending'),
          createdAt: like('2024-01-01T00:00:00Z'),
        }),
      })
      .executeTest(async (mockServer) => {
        const client = new OrdersClient(mockServer.url);
        const orders = await client.getOrders('Bearer token123');

        expect(orders).toHaveLength(1);
        expect(orders[0].status).toBe('pending');
      });
  });
});
```

## Provider Verification

```typescript
import { Verifier } from '@pact-foundation/pact';

describe('Provider verification', () => {
  it('validates against consumer contracts', async () => {
    await new Verifier({
      providerBaseUrl: 'http://localhost:3000',
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,
      provider: 'OrdersAPI',
      publishVerificationResult: process.env.CI === 'true',
      providerVersion: process.env.GIT_SHA,
      stateHandlers: {
        'user has orders': async () => {
          await seedTestOrders();  // Set up provider state
        },
        'no orders exist': async () => {
          await clearOrders();
        },
      },
    }).verifyProvider();
  });
});
```

## Pact Broker & can-i-deploy

```bash
# Publish consumer contract to broker
pact-broker publish pacts/ \
  --consumer-app-version=$GIT_SHA \
  --branch=$GIT_BRANCH \
  --broker-base-url=$PACT_BROKER_URL

# Check if safe to deploy (all contracts verified)
pact-broker can-i-deploy \
  --pacticipant=OrdersUI \
  --version=$GIT_SHA \
  --to-environment=production

# Record deployment
pact-broker record-deployment \
  --pacticipant=OrdersUI \
  --version=$GIT_SHA \
  --environment=production
```

## Anti-patterns
- Testing business logic in contract tests → only test API shape
- Exact match instead of matchers → brittle contracts
- No state handlers → provider tests fail due to missing data
- Skipping can-i-deploy → deploy breaks consumers

## Quick reference
```
Consumer: defines contract (what it expects from provider)
Provider: verifies contract (proves it fulfills expectations)
Matchers: like() for type, regex() for format, eachLike() for arrays
State handlers: set up provider data for each test scenario
Broker: central store for contracts + verification results
can-i-deploy: gate deployment on verified contracts
Flow: consumer test → publish → provider verify → can-i-deploy → deploy
```
