---
name: role-fullstack:real-time-features
description: Implement real-time features using WebSockets (Socket.io, ws), Server-Sent Events (SSE), Supabase Realtime, Firebase, or Pusher. Covers presence indicators, live cursors, CRDT-based collaborative editing (Yjs, Automerge), notifications with offline delivery, chat with optimistic rendering, and Redis Pub/Sub backplane for multi-node scaling. Use when adding live updates, chat, collaboration, or any server-to-client or bidirectional communication.
allowed-tools: Read, Grep, Glob, Bash
---

# Real-Time Features

## When to use
- Adding live notifications or activity feeds
- Building a chat system or typing indicators
- Implementing presence indicators (online/idle/offline)
- Adding collaborative editing or live cursors
- Streaming data to a dashboard in real time
- Scaling WebSocket connections across multiple server instances

## Core principles
1. **Transport matches use case** — SSE for server-push feeds and dashboards; Socket.io for rooms, chat, and bidirectional events; managed services (Pusher, Ably) when infra ownership is not worth it
2. **Authenticate before accepting** — validate JWT or session cookie in the Socket.io connection middleware; never allow anonymous socket joins to protected rooms
3. **Always clean up subscriptions** — every `eventBus.on` and every `socket.join` needs a corresponding teardown on disconnect or component unmount
4. **Deltas over full state** — emit only what changed; sending full document snapshots on every keystroke kills throughput and battery
5. **Redis backplane for multi-node** — a single Socket.io Redis adapter call is all that stands between "works on one dyno" and "works on ten"

## Reference Files

- `references/websockets-sse.md` — technology selection table, Socket.io five-step server setup, SSE ReadableStream implementation for Next.js route handlers, scaling with Redis Pub/Sub and sticky sessions
- `references/presence-collaboration-chat.md` — presence heartbeat with Redis sorted sets, Yjs/Automerge CRDT integration with TipTap/Lexical, notifications pipeline (online WebSocket + offline queue), chat message model and cursor-based pagination, common pitfalls
