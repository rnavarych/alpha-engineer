# Local Database Options & Conflict Resolution

## When to load
Load when choosing a local database for offline storage or designing conflict resolution strategies for multi-device or server sync scenarios.

## Local Database Options

### WatermelonDB (React Native)
- Lazy loading with SQLite backend — fast even with 100K+ records
- Observable queries that re-render React components on data change
- Built-in sync protocol: `synchronize()` with push/pull functions
- Schema migrations with `schemaMigrations` for version management
- Runs queries on a separate thread — does not block JS thread
- Best for React Native apps with large datasets and sync requirements

### Realm (React Native / iOS / Android)
- Object-oriented database with live objects (auto-updating references)
- Realm Sync with MongoDB Atlas for built-in cloud sync
- Schema defined in code with typed models
- Supports relationships, embedded objects, and mixed types
- Encryption at rest with 256-bit AES
- Best when using MongoDB Atlas backend or needing object-graph persistence

### Hive (Flutter)
- Lightweight key-value store with TypeAdapter for custom objects
- Fast read/write — suitable for settings, caches, and small datasets
- No SQL overhead — binary serialization
- LazyBox for large datasets (load entries on access)
- Encryption support with AES-256
- Best for Flutter apps with simpler data models

### SQLite (All Platforms)
- iOS: Core Data / SwiftData (wrappers), GRDB.swift (direct)
- Android: Room (Jetpack wrapper), SQLDelight (Kotlin multiplatform)
- React Native: `expo-sqlite`, `react-native-quick-sqlite`
- Flutter: `sqflite`, `drift` (type-safe wrapper with code generation)
- Best for complex queries, relational data, and maximum portability

## Conflict Resolution

### Last-Write-Wins (LWW)
- Simplest strategy: most recent timestamp wins
- Use server timestamps (not device clocks) to avoid clock skew issues
- Works well for single-user data or when data loss is acceptable
- Not suitable for collaborative editing

### Field-Level Merge
- Track changes per field rather than per record
- Merge non-conflicting field changes automatically
- Flag conflicting fields for user resolution
- More complex to implement but preserves more data

### CRDT (Conflict-Free Replicated Data Types)
- Mathematically guaranteed convergence without coordination
- Types: G-Counter, PN-Counter, LWW-Register, OR-Set, RGA (text)
- Libraries: Automerge, Yjs, or custom implementations
- Higher storage overhead (state metadata) but zero conflicts
- Best for real-time collaboration and multi-device sync

### Operational Transform (OT)
- Used in collaborative text editing (Google Docs approach)
- Transform concurrent operations to maintain consistency
- Requires central server for operation ordering
- Complex implementation — prefer CRDTs for new projects
