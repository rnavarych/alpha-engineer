# WebSockets and SSE Implementation

## When to load
Load when implementing Socket.io WebSocket connections, SSE streams, or evaluating bidirectional vs server-push transport options.

## Technology Selection

| Technology         | Direction       | Complexity | Best For                              |
|--------------------|-----------------|------------|---------------------------------------|
| WebSocket (ws)     | Bidirectional   | Medium     | Custom protocols, high-frequency data |
| Socket.io          | Bidirectional   | Low        | Chat, notifications, rooms/namespaces |
| SSE                | Server-to-client| Low        | Live feeds, dashboards, notifications |
| Supabase Realtime  | Bidirectional   | Low        | Postgres-backed real-time, presence   |
| Firebase RTDB      | Bidirectional   | Low        | Mobile-first, offline sync            |
| Pusher / Ably      | Bidirectional   | Low        | Managed, multi-region, no infra       |

## WebSocket Implementation (Socket.io)

1. **Server setup** — create a Socket.io server alongside the HTTP server. Use namespaces to separate concerns (`/chat`, `/notifications`).
2. **Authentication** — validate the JWT or session cookie in the `connection` middleware before allowing the socket to join.
3. **Rooms** — use rooms for scoping broadcasts (e.g., `socket.join(\`project:\${projectId}\`)`).
4. **Event schema** — define typed event maps shared between server and client for type-safe `emit` and `on`.
5. **Reconnection** — Socket.io handles reconnection automatically. On reconnect, re-join rooms and fetch missed events via a REST fallback.

## Server-Sent Events (SSE)

```typescript
// Next.js Route Handler for SSE
export async function GET(req: Request) {
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      const send = (data: unknown) => {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(data)}\n\n`));
      };
      // Subscribe to events
      const unsubscribe = eventBus.on('update', send);
      req.signal.addEventListener('abort', () => {
        unsubscribe();
        controller.close();
      });
    },
  });
  return new Response(stream, {
    headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' },
  });
}
```

## Scaling Considerations

- Use Redis Pub/Sub or a message broker (NATS, RabbitMQ) as a backplane when running multiple server instances.
- Sticky sessions or a shared adapter (Socket.io Redis adapter) for multi-node WebSocket deployments.
- Rate-limit event emission to prevent abuse (max 10 messages/second per user).
