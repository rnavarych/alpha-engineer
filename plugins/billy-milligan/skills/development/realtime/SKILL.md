---
name: realtime
description: |
  Real-time patterns: SSE with Redis Pub/Sub and heartbeat, Socket.IO with Redis adapter
  for multi-server, Supabase Realtime CDC, WebSocket reconnection with exponential backoff,
  choosing SSE vs WebSockets vs polling. Use when building live updates, notifications,
  collaborative features, real-time dashboards.
allowed-tools: Read, Grep, Glob
---

# Real-Time Patterns

## When to Use This Skill
- Building live notifications, dashboards, or collaborative features
- Choosing between SSE, WebSockets, and polling
- Scaling real-time to multiple server instances
- Implementing reconnection with backoff
- Setting up Supabase Realtime for database changes

## Core Principles

1. **SSE for server-to-client** — simpler than WebSockets, auto-reconnects, HTTP/2 multiplexed
2. **WebSockets for bidirectional** — when client sends frequent messages (chat, multiplayer)
3. **Redis Pub/Sub for multi-instance** — events published on one server must reach all clients
4. **Always heartbeat** — detect stale connections; proxies and load balancers kill idle connections
5. **Exponential backoff on reconnect** — avoid stampede when server restarts

---

## Patterns ✅

### Server-Sent Events (SSE) with Redis Pub/Sub

Best for: notifications, live feeds, dashboards. Client reads only.

```typescript
// server: SSE endpoint
app.get('/api/notifications/stream', requireAuth, async (req, res) => {
  const userId = req.user.id;

  // SSE headers
  res.set({
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'X-Accel-Buffering': 'no',  // Disable nginx buffering
  });

  // Send initial connection event
  res.write(`data: ${JSON.stringify({ type: 'connected' })}\n\n`);

  // Subscribe to user's channel in Redis
  const subscriber = redis.duplicate();  // Separate connection for subscribe
  await subscriber.subscribe(`notifications:${userId}`);

  const onMessage = (channel: string, message: string) => {
    res.write(`data: ${message}\n\n`);
  };
  subscriber.on('message', onMessage);

  // Heartbeat — prevents proxy/LB from closing idle connections
  const heartbeat = setInterval(() => {
    res.write(': heartbeat\n\n');  // Comment line — not parsed by EventSource
  }, 30_000);  // Every 30 seconds

  // Cleanup on client disconnect
  req.on('close', async () => {
    clearInterval(heartbeat);
    subscriber.off('message', onMessage);
    await subscriber.unsubscribe(`notifications:${userId}`);
    await subscriber.quit();
  });
});

// Publish notification from anywhere
async function sendNotification(userId: string, notification: Notification) {
  await db.notifications.create({ data: { ...notification, userId } });
  await redis.publish(`notifications:${userId}`, JSON.stringify(notification));
}
```

```typescript
// client: EventSource with reconnection
function connectSSE(userId: string) {
  const evtSource = new EventSource(`/api/notifications/stream`);

  evtSource.onmessage = (event) => {
    const notification = JSON.parse(event.data);
    if (notification.type !== 'connected') {
      displayNotification(notification);
    }
  };

  evtSource.onerror = () => {
    // EventSource auto-reconnects with exponential backoff natively
    // Default reconnect: 3 seconds, configurable via retry: N\n\n
    console.log('SSE connection lost — auto-reconnecting');
  };

  return evtSource;
}
```

### Socket.IO with Redis Adapter (Multi-Server)

Best for: chat, collaborative editing, multiplayer — bidirectional communication.

```typescript
// server: Socket.IO with Redis adapter
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';

const io = new Server(httpServer, {
  cors: { origin: process.env.CLIENT_URL, credentials: true },
  pingInterval: 25_000,  // Ping client every 25s
  pingTimeout: 5_000,    // Disconnect if no pong in 5s
});

// Redis adapter: events published on server A reach clients on servers B and C
const pubClient = redis.duplicate();
const subClient = redis.duplicate();
io.adapter(createAdapter(pubClient, subClient));

// Authentication middleware
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  try {
    socket.data.user = verifyAccessToken(token);
    next();
  } catch {
    next(new Error('unauthorized'));
  }
});

// Connection handler
io.on('connection', (socket) => {
  const userId = socket.data.user.sub;

  // Join user's room
  socket.join(`user:${userId}`);

  socket.on('join_room', (roomId: string) => {
    socket.join(`room:${roomId}`);
  });

  socket.on('message', async (data: { roomId: string; content: string }) => {
    const message = await messageService.create({
      roomId: data.roomId,
      userId,
      content: data.content,
    });
    // Emit to all in room (including sender) — across all server instances
    io.to(`room:${data.roomId}`).emit('message', message);
  });

  socket.on('disconnect', () => {
    logger.info({ userId }, 'WebSocket disconnected');
  });
});

// Send to specific user from anywhere (works across server instances via Redis)
async function notifyUser(userId: string, event: string, data: unknown) {
  io.to(`user:${userId}`).emit(event, data);
}
```

### Client Reconnection with Exponential Backoff

```typescript
// WebSocket client with exponential backoff
function createReconnectingWebSocket(url: string, onMessage: (data: unknown) => void) {
  let ws: WebSocket | null = null;
  let reconnectDelay = 1000;  // Start at 1 second
  const maxDelay = 30_000;    // Max 30 seconds
  let reconnectTimer: ReturnType<typeof setTimeout>;
  let intentionalClose = false;

  function connect() {
    ws = new WebSocket(url);

    ws.onopen = () => {
      reconnectDelay = 1000;  // Reset delay on successful connection
      console.log('WebSocket connected');
    };

    ws.onmessage = (event) => {
      onMessage(JSON.parse(event.data));
    };

    ws.onclose = (event) => {
      if (intentionalClose) return;
      console.log(`WebSocket closed (code: ${event.code}) — reconnecting in ${reconnectDelay}ms`);
      reconnectTimer = setTimeout(() => {
        reconnectDelay = Math.min(reconnectDelay * 2, maxDelay);
        connect();
      }, reconnectDelay);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }

  connect();

  return {
    send: (data: unknown) => ws?.send(JSON.stringify(data)),
    close: () => {
      intentionalClose = true;
      clearTimeout(reconnectTimer);
      ws?.close();
    },
  };
}
```

### Choosing: SSE vs WebSockets vs Polling

| Criteria | SSE | WebSockets | Long Polling |
|----------|-----|------------|--------------|
| Direction | Server → client only | Bidirectional | Server → client |
| Auto-reconnect | Yes (native) | No (manual) | Yes (each request) |
| Proxy/LB compatible | Yes (standard HTTP) | Needs upgrade | Yes |
| HTTP/2 multiplexed | Yes | No (separate TCP) | No |
| Use case | Notifications, feeds | Chat, multiplayer | Legacy fallback |
| Server complexity | Low | Medium | Medium |
| Client complexity | Low | Medium | Medium |

**Rule of thumb**:
- Server → client only: **SSE** (simpler, less overhead)
- Bidirectional with >1 message/sec: **WebSockets**
- Bidirectional with <1 message/sec: **SSE + REST for client messages**

---

## Anti-Patterns ❌

### Polling Instead of SSE/WebSockets
**What it is**: `setInterval(() => fetch('/api/notifications'), 5000)` — poll every 5 seconds.
**What breaks**: 1000 users × 1 request/5s = 200 requests/second of wasted traffic. All return empty responses 99% of the time. Server load with no real-time benefit.
**When polling is OK**: Low-traffic, simple integrations where SSE setup isn't worth it. Max acceptable: once per 30 seconds.

### No Heartbeat on SSE
**What it is**: SSE connection without periodic heartbeat.
**What breaks**: Many proxies and load balancers (nginx, AWS ALB) close idle connections after 60 seconds. Connection appears open to client but is actually dead. Client stops receiving events, doesn't know it.
**Fix**: Send `: heartbeat\n\n` every 30 seconds. Use `evtSource.onerror` to detect and reconnect.

### Single Redis Pub/Sub Connection for Subscribe + Publish
**What it is**: Using the same Redis connection for both publishing and subscribing.
**What breaks**: A Redis connection in SUBSCRIBE mode cannot issue any other commands. Your `redis.set()` will fail or block.
**Fix**: Always duplicate the Redis client for subscribe. `const subscriber = redis.duplicate()`

---

## Quick Reference

```
SSE headers: Content-Type: text/event-stream, X-Accel-Buffering: no
SSE heartbeat: ": heartbeat\n\n" every 30s
SSE vs WS: SSE for server-to-client only; WS for bidirectional >1 msg/s
Redis Pub/Sub: duplicate connection for subscribe (cannot mix with commands)
Socket.IO Redis adapter: events cross server instances automatically
Reconnect backoff: 1s → 2s → 4s → ... → 30s max
Socket.IO ping: pingInterval: 25000, pingTimeout: 5000
Multi-server: must use Redis adapter — in-memory state is per-instance only
```
