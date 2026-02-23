# Server-Sent Events (SSE)

## When to load
Load when implementing server-to-client push: notifications, live feeds, progress updates.

## Implementation

```typescript
// Express/Fastify SSE endpoint
app.get('/events/:userId', async (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive',
    'X-Accel-Buffering': 'no', // Nginx: disable proxy buffering
  });

  // Heartbeat every 30s — prevents proxy/LB timeout
  const heartbeat = setInterval(() => res.write(':heartbeat\n\n'), 30_000);

  // Redis Pub/Sub for multi-server support
  const subscriber = redis.duplicate();
  await subscriber.subscribe(`user:${req.params.userId}`);

  subscriber.on('message', (channel, message) => {
    const data = JSON.parse(message);
    res.write(`event: ${data.type}\ndata: ${JSON.stringify(data.payload)}\nid: ${data.id}\n\n`);
  });

  req.on('close', () => {
    clearInterval(heartbeat);
    subscriber.unsubscribe();
    subscriber.quit();
  });
});
```

```typescript
// Client: EventSource with auto-reconnect
const es = new EventSource('/events/user123');

es.addEventListener('notification', (e) => {
  const data = JSON.parse(e.data);
  showNotification(data);
});

es.addEventListener('error', () => {
  // EventSource auto-reconnects with Last-Event-ID header
  console.log('SSE connection lost, reconnecting...');
});
```

## When to choose SSE
- Server → client only (no bidirectional needed)
- Text/JSON data (no binary)
- Auto-reconnect with Last-Event-ID built into browser
- Works through HTTP/2 multiplexing (no connection limit)

## Anti-patterns
- No heartbeat → proxy closes idle connection after 60s
- Missing `X-Accel-Buffering: no` → Nginx buffers events
- Single-server state → SSE breaks when client reconnects to different instance

## Quick reference
```
Content-Type: text/event-stream
Heartbeat: :heartbeat\n\n every 30s
Format: event: type\ndata: json\nid: uuid\n\n
Reconnect: automatic with Last-Event-ID
Multi-server: Redis Pub/Sub or similar
Max connections: HTTP/2 = unlimited, HTTP/1.1 = 6 per domain
```
