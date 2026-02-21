---
name: real-time-features
description: |
  Implement real-time features using WebSockets (Socket.io, ws), Server-Sent
  Events (SSE), Supabase Realtime, Firebase, or Pusher. Covers presence
  indicators, live cursors, collaborative editing, notifications, and chat.
allowed-tools: Read, Grep, Glob, Bash
---

# Real-Time Features

## When to Use

Activate when adding live updates, notifications, chat, collaborative editing, presence indicators, or any feature requiring server-to-client or bidirectional communication.

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

1. **Server setup** -- create a Socket.io server alongside the HTTP server. Use namespaces to separate concerns (`/chat`, `/notifications`).
2. **Authentication** -- validate the JWT or session cookie in the `connection` middleware before allowing the socket to join.
3. **Rooms** -- use rooms for scoping broadcasts (e.g., `socket.join(\`project:\${projectId}\`)`).
4. **Event schema** -- define typed event maps shared between server and client for type-safe `emit` and `on`.
5. **Reconnection** -- Socket.io handles reconnection automatically. On reconnect, re-join rooms and fetch missed events via a REST fallback.

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

## Presence Indicators

- Track online status with a heartbeat (ping every 30s, timeout after 60s).
- Use Supabase Presence or a Redis sorted set (`ZADD presence <timestamp> <userId>`) with periodic cleanup.
- Broadcast presence changes to relevant rooms/channels.
- Show avatar dots (green = online, yellow = idle, gray = offline) in the UI.

## Live Cursors / Collaborative Editing

- Use CRDT libraries (Yjs, Automerge) for conflict-free collaborative editing.
- Broadcast cursor positions via WebSocket with throttling (50ms interval).
- Render remote cursors with distinct colors and user labels.
- For rich text, integrate Yjs with TipTap, Lexical, or ProseMirror.

## Notifications System

1. **Server** -- emit events on relevant actions (new comment, assignment, status change).
2. **Transport** -- deliver via WebSocket for online users, queue for offline delivery (email, push).
3. **Client** -- maintain a notification store (TanStack Query with WebSocket invalidation). Show badge count and toast for new items.
4. **Persistence** -- store notifications in DB with `read` boolean. Provide "Mark all read" and per-notification dismiss.

## Chat Implementation

- Message model: `id`, `channelId`, `senderId`, `content`, `createdAt`, `updatedAt`, `deletedAt`.
- Use optimistic rendering: show the message immediately, confirm or rollback on server response.
- Implement message pagination (cursor-based, load older messages on scroll up).
- Support typing indicators with debounced emit (start typing, stop after 2s inactivity).

## Scaling Considerations

- Use Redis Pub/Sub or a message broker (NATS, RabbitMQ) as a backplane when running multiple server instances.
- Sticky sessions or a shared adapter (Socket.io Redis adapter) for multi-node WebSocket deployments.
- Rate-limit event emission to prevent abuse (max 10 messages/second per user).

## Common Pitfalls

- Not cleaning up subscriptions on component unmount -- always return cleanup functions.
- Sending full state on every update instead of deltas -- use patches for efficiency.
- Ignoring reconnection edge cases -- always reconcile state after reconnection.
- Missing authentication on WebSocket connections -- always validate before accepting.
