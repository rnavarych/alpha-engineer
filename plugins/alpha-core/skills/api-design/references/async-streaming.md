# Async and Streaming APIs

## When to load
Load when working with SSE, WebSockets, long polling, AsyncAPI, event-driven architectures, webhooks, or CloudEvents.

## Server-Sent Events (SSE)

One-way server-to-client streaming over HTTP. Ideal for AI LLM streaming responses.

```javascript
// Server (Node.js/Express)
app.get('/events', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'X-Accel-Buffering': 'no',  // Disable nginx buffering
  });
  const send = (event, data) => res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\nid: ${Date.now()}\n\n`);
  const lastId = req.headers['last-event-id']; // resume from last event on reconnect
  const interval = setInterval(() => send('update', { ts: Date.now() }), 1000);
  req.on('close', () => clearInterval(interval));
});

const es = new EventSource('/events');
es.addEventListener('update', (e) => console.log(JSON.parse(e.data)));
```

## Long Polling Pattern

```javascript
app.get('/api/updates', async (req, res) => {
  const result = await Promise.race([waitForUpdate(req.query.since), sleep(30000).then(() => null)]);
  res.json({ data: result ?? null, timestamp: Date.now() });
});
async function poll(since = 0) {
  const { data, timestamp } = await fetch(`/api/updates?since=${since}`).then(r => r.json());
  if (data) handleUpdate(data);
  poll(timestamp);
}
```

## AsyncAPI for Event-Driven APIs

```yaml
asyncapi: '3.0.0'
info:
  title: Order Events API
  version: '1.0.0'
channels:
  order/created:
    address: order.created
    messages:
      OrderCreated:
        payload:
          type: object
          properties:
            orderId: { type: string, format: uuid }
            totalAmount: { type: number }
    bindings:
      kafka:
        topic: order-created-events
        partitions: 12
        replicas: 3
```

- Tools: AsyncAPI Studio (visual editor), asyncapi-generator (code gen), Microcks (mock server)
- CloudEvents envelope: `specversion`, `type`, `source`, `id`, `time`, `datacontenttype`, `data`

## Webhook Delivery

```javascript
// Signing (Standard Webhooks Spec)
const timestamp = Math.floor(Date.now() / 1000).toString();
const signature = crypto.createHmac('sha256', secret).update(`${timestamp}.${JSON.stringify(payload)}`).digest('hex');
headers['webhook-id'] = eventId;
headers['webhook-timestamp'] = timestamp;
headers['webhook-signature'] = `v1,${signature}`;

// Receiver verification — always check timestamp age to prevent replay
function verifyWebhook(payload, headers, secret) {
  const age = Math.abs(Date.now() / 1000 - parseInt(headers['webhook-timestamp']));
  if (age > 300) throw new Error('Timestamp too old');
  const toVerify = `${headers['webhook-id']}.${headers['webhook-timestamp']}.${payload}`;
  const expected = `v1,${crypto.createHmac('sha256', secret).update(toVerify).digest('hex')}`;
  const sigs = headers['webhook-signature'].split(' ');
  if (!sigs.some(sig => crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected))))
    throw new Error('Invalid signature');
}
```

**Retry strategy**: immediate → 5s → 30s → 2m → 10m → 30m → 1h → 6h → 12h → 24h → dead letter queue

**Architecture**: Producer → Event Store (outbox) → Webhook Dispatcher → HTTP with retries → DLQ on failure

- **Svix**: Managed webhook service, retries, signature verification, portal, SDKs
- **Hookdeck**: Webhook gateway, routing, filtering, retry policies, transformations
- Idempotency key in payload for consumer deduplication
- Webhook testing: ngrok, localtunnel, Svix CLI, Hookdeck CLI for local development
