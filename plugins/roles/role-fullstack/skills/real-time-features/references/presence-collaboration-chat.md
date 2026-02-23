# Presence, Collaboration, and Chat

## When to load
Load when building presence indicators, live cursors, collaborative editing, notifications, or a chat system.

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

1. **Server** — emit events on relevant actions (new comment, assignment, status change).
2. **Transport** — deliver via WebSocket for online users, queue for offline delivery (email, push).
3. **Client** — maintain a notification store (TanStack Query with WebSocket invalidation). Show badge count and toast for new items.
4. **Persistence** — store notifications in DB with `read` boolean. Provide "Mark all read" and per-notification dismiss.

## Chat Implementation

- Message model: `id`, `channelId`, `senderId`, `content`, `createdAt`, `updatedAt`, `deletedAt`.
- Use optimistic rendering: show the message immediately, confirm or rollback on server response.
- Implement message pagination (cursor-based, load older messages on scroll up).
- Support typing indicators with debounced emit (start typing, stop after 2s inactivity).

## Common Pitfalls

- Not cleaning up subscriptions on component unmount — always return cleanup functions.
- Sending full state on every update instead of deltas — use patches for efficiency.
- Ignoring reconnection edge cases — always reconcile state after reconnection.
- Missing authentication on WebSocket connections — always validate before accepting.
