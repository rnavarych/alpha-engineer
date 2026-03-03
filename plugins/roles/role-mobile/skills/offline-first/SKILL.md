---
name: role-mobile:offline-first
description: Expert guidance on offline-first mobile architecture — local database sync (WatermelonDB, Realm, Hive, SQLite), conflict resolution strategies (last-write-wins, CRDT), optimistic UI patterns, background sync (WorkManager, BGTaskScheduler), and connectivity detection. Use when designing apps that must work reliably without network connectivity.
allowed-tools: Read, Grep, Glob, Bash
---

# Offline-First Architecture

## When to use
- Designing an app that must function fully without network connectivity
- Choosing a local database for offline storage (WatermelonDB, Realm, Hive, SQLite)
- Defining conflict resolution rules before a sync feature is built
- Implementing optimistic UI updates with mutation queues
- Setting up background sync with WorkManager (Android) or BGTaskScheduler (iOS)
- Handling connectivity detection, reachability checks, and retry strategies

## Core principles
1. **Network is optional** — the app is fully usable offline; sync is background enrichment
2. **Local-first reads** — always read from local DB; never block UI on a network call
3. **Optimistic writes** — apply locally first, queue for server, reconcile on response
4. **Conflict rules before code** — LWW is simple; CRDT is correct; decide before building, not after
5. **Partial sync is the norm** — background tasks get killed; design every sync step to resume cleanly

## Reference Files

- `references/local-db-conflict.md` — WatermelonDB, Realm, Hive, and SQLite comparison for offline storage, last-write-wins strategy, field-level merge, CRDT types and libraries (Automerge, Yjs), Operational Transform tradeoffs
- `references/sync-connectivity.md` — core offline-first principles, optimistic UI pattern and mutation queue implementation, Android WorkManager background sync, iOS BGTaskScheduler, cross-platform background fetch, connectivity detection libraries and best practices, exponential backoff strategy
