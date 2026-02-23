# Realm, ObjectBox, and libSQL

## When to load
Load when building mobile apps (iOS/Android with Realm or ObjectBox/Dart), or when using libSQL/Turso for edge-replicated SQLite with vector search.

## Realm — Mobile Object Database

```swift
// Swift (iOS) — live objects, MVCC, Atlas Device Sync
import RealmSwift

class Order: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var customerName: String
    @Persisted var amount: Double
    @Persisted var status: String = "pending"
    @Persisted var items: List<OrderItem>
    @Persisted var createdAt: Date = Date()
}

// Schema migration
let config = Realm.Configuration(schemaVersion: 2, migrationBlock: { migration, oldVersion in
    if oldVersion < 2 { /* migration logic */ }
})
let realm = try! Realm(configuration: config)

// Write transaction
try! realm.write {
    let order = Order()
    order.customerName = "Alice"; order.amount = 99.99
    realm.add(order)
}

// Live objects: auto-update when underlying data changes
let orders = realm.objects(Order.self)
    .filter("status == 'pending'")
    .sorted(byKeyPath: "createdAt")
let token = orders.observe { changes in /* update UI */ }

// Atlas Device Sync (cloud sync)
let app = App(id: "myapp-xxxxx")
let user = try await app.login(credentials: .anonymous)
let config = user.flexibleSyncConfiguration { subs in
    subs.append(QuerySubscription<Order>(name: "my-orders") { $0.customerName == user.id })
}
let realm = try await Realm(configuration: config)
```

## ObjectBox — Flutter/Dart/IoT

```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class Order {
  @Id() int id = 0;
  String customerName;
  double amount;
  String status;
  @Property(type: PropertyType.date) DateTime createdAt;

  // Embedded vector for similarity search
  @HnswIndex(dimensions: 128, distanceType: VectorDistanceType.cosine)
  Float32List? embedding;
}

final store = await openStore();
final box = store.box<Order>();

box.put(Order('Alice', 99.99));

// Query
final pending = box.query(Order_.status.equals('pending'))
    .order(Order_.createdAt, flags: Order.descending)
    .build().find();

// Vector similarity search
final similar = box.query(Order_.embedding.nearestNeighborsF32(queryVector, 10))
    .build().find();
```

## libSQL (Turso SQLite Fork)

```bash
curl -sSfL https://get.tur.so/install.sh | bash
turso db create my-app
```

```typescript
import { createClient } from '@libsql/client';

// Embedded replica: local reads, sync from remote
const client = createClient({
  url: 'file:local.db',
  syncUrl: 'libsql://my-app-user.turso.io',
  authToken: 'eyJ...',
  syncInterval: 60,  // seconds
});

await client.sync();

await client.execute(
  'INSERT INTO orders (customer, amount) VALUES (?, ?)',
  ['Alice', 99.99]
);

// Vector search (libSQL extension)
await client.execute(`CREATE TABLE documents (id INTEGER PRIMARY KEY, content TEXT, embedding F32_BLOB(384))`);
await client.execute(`CREATE INDEX documents_idx ON documents (libsql_vector_idx(embedding, 'metric=cosine'))`);

const similar = await client.execute(
  `SELECT id, content, vector_distance_cos(embedding, vector(?)) AS distance
   FROM vector_top_k('documents_idx', vector(?), 10)
   JOIN documents ON documents.rowid = id`,
  [queryEmbedding, queryEmbedding]);
```

**Use libSQL when**: need SQLite with server mode, HTTP API, embedded replicas for edge, or vector similarity search.
