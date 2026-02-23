# WebSocket Patterns

## When to load
Load when implementing bidirectional real-time: chat, multiplayer, collaborative editing.

## Socket.IO with Redis Adapter

```typescript
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

const pubClient = createClient({ url: process.env.REDIS_URL });
const subClient = pubClient.duplicate();
await Promise.all([pubClient.connect(), subClient.connect()]);

const io = new Server(server, {
  adapter: createAdapter(pubClient, subClient), // Multi-server support
  cors: { origin: process.env.CLIENT_URL },
  pingInterval: 25_000,  // Client heartbeat
  pingTimeout: 20_000,   // Disconnect if no pong
});

// Auth middleware
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  try {
    const user = await verifyJWT(token);
    socket.data.userId = user.id;
    next();
  } catch {
    next(new Error('Unauthorized'));
  }
});

// Room-based messaging
io.on('connection', (socket) => {
  socket.join(`user:${socket.data.userId}`);

  socket.on('join-room', (roomId) => {
    socket.join(`room:${roomId}`);
  });

  socket.on('message', async (data) => {
    const saved = await db.messages.create({ data });
    io.to(`room:${data.roomId}`).emit('message', saved);
  });
});

// Send to specific user (works across servers via Redis)
io.to(`user:${userId}`).emit('notification', payload);
```

## Client Reconnection

```typescript
import { io } from 'socket.io-client';

const socket = io(process.env.WS_URL, {
  auth: { token: getAccessToken() },
  reconnection: true,
  reconnectionDelay: 1000,        // Start at 1s
  reconnectionDelayMax: 30_000,   // Cap at 30s
  reconnectionAttempts: Infinity,
  transports: ['websocket'],      // Skip long-polling
});

socket.on('connect', () => {
  // Re-join rooms after reconnect
  activeRooms.forEach(room => socket.emit('join-room', room));
});

socket.on('connect_error', (err) => {
  if (err.message === 'Unauthorized') {
    refreshToken().then(token => {
      socket.auth = { token };
      socket.connect();
    });
  }
});
```

## Decision: SSE vs WebSocket vs Polling

| Criteria | SSE | WebSocket | Polling |
|----------|-----|-----------|---------|
| Direction | Server→Client | Bidirectional | Client→Server |
| Protocol | HTTP | WS (upgrade) | HTTP |
| Auto-reconnect | Built-in | Manual | N/A |
| Binary data | No | Yes | Yes |
| Proxy-friendly | Yes | Sometimes | Yes |
| Use case | Notifications, feeds | Chat, gaming | Legacy, simple |

## Anti-patterns
- Storing socket state in memory only → lost on server restart
- Not authenticating WebSocket connections → anyone can connect
- Using WebSocket for server→client only → SSE is simpler
- No reconnection logic → client stays disconnected forever

## Quick reference
```
Socket.IO: bidirectional, rooms, Redis adapter for multi-server
Auth: verify JWT in io.use() middleware
Rooms: socket.join('room:id'), io.to('room:id').emit()
Reconnect: exponential backoff 1s→30s, re-join rooms on connect
Heartbeat: pingInterval 25s, pingTimeout 20s
Transport: prefer 'websocket' over long-polling
```
