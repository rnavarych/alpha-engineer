# Optimistic UI, Background Sync & Connectivity

## When to load
Load when implementing optimistic UI updates, background sync workers, or connectivity detection and retry logic for offline-first apps.

## Core Principles

1. **Network is a luxury, not a requirement** — the app must be fully functional offline
2. **Local-first**: read from local database, sync to server in background
3. **Optimistic updates**: apply changes locally immediately, reconcile with server later
4. **Conflict resolution**: define clear rules before building — conflicts will happen
5. **Transparency**: show sync status to users (synced, pending, conflict, error)

## Optimistic UI

### Pattern
1. Apply mutation to local database immediately
2. Update UI to reflect the change with no loading state
3. Queue the mutation for server sync
4. On success: mark as synced (no UI change needed)
5. On failure: show error, offer retry or revert

### Implementation
- Maintain a mutation queue with retry logic and exponential backoff
- Each mutation has: ID, type, payload, status (pending/syncing/failed/synced), retry count
- Order-dependent mutations must be sent sequentially
- Idempotent server endpoints: use client-generated UUIDs for deduplication
- Show subtle sync indicators (not blocking spinners) for pending mutations

## Background Sync

### Android (WorkManager)
- Use `PeriodicWorkRequest` for recurring sync (minimum 15-minute interval)
- Set constraints: `NetworkType.CONNECTED`, `requiresBatteryNotLow`
- Use `ExistingPeriodicWorkPolicy.KEEP` to avoid duplicate sync workers
- Chain sync operations: download -> merge -> upload -> cleanup
- Report progress with `setProgress` for observable sync status

### iOS (BGTaskScheduler)
- Register `BGAppRefreshTask` for periodic sync (system determines timing)
- Register `BGProcessingTask` for heavy sync (database migration, large uploads)
- Request execution with `BGTaskRequest` and `earliestBeginDate`
- Complete tasks within time limit or the system terminates the app
- Submit task requests in `applicationDidEnterBackground` or `sceneDidEnterBackground`

### Cross-Platform
- React Native: `react-native-background-fetch` for periodic background sync
- Flutter: `workmanager` package wrapping WorkManager and BGTaskScheduler
- Always handle partial sync — sync can be interrupted at any point

## Connectivity Detection

### Detection
- iOS: `NWPathMonitor` for real-time network status and interface type
- Android: `ConnectivityManager.NetworkCallback` for connectivity changes
- React Native: `@react-native-community/netinfo` for cross-platform detection
- Flutter: `connectivity_plus` for connectivity changes, `internet_connection_checker` for actual reachability

### Best Practices
- Do not trust connectivity status alone — a connected network may have no internet
- Verify actual reachability with a lightweight health check endpoint
- Use exponential backoff for retries: 1s, 2s, 4s, 8s (cap at 5 minutes)
- Queue requests during offline state, flush queue when connectivity returns
- Distinguish between: no network, captive portal, server unreachable, and timeout
- Show connectivity status in UI but avoid blocking user actions
