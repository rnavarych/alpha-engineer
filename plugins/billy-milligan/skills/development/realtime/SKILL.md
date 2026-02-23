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

## When to use
- Building live notifications, dashboards, or collaborative features
- Choosing between SSE, WebSockets, and polling
- Scaling real-time to multiple server instances
- Implementing reconnection with backoff
- Setting up Supabase Realtime for database changes

## Core principles
1. **SSE for server-to-client** — simpler than WebSockets, auto-reconnects, HTTP/2 multiplexed
2. **WebSockets for bidirectional** — when client sends frequent messages (chat, multiplayer)
3. **Redis Pub/Sub for multi-instance** — events published on one server must reach all clients
4. **Always heartbeat** — detect stale connections; proxies and load balancers kill idle connections
5. **Exponential backoff on reconnect** — avoid stampede when server restarts

## References available
- `references/sse-patterns.md` — SSE endpoint setup, Redis Pub/Sub integration, heartbeat, client EventSource
- `references/websocket-patterns.md` — Socket.IO multi-server with Redis adapter, reconnection backoff
- `references/supabase-realtime.md` — Supabase Realtime CDC, channel subscriptions, presence
