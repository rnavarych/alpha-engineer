# Data Migration Patterns

## When to load
Load when discussing large-scale data migration, ETL pipelines, dual-write between databases, batch processing of existing rows, or moving data between storage engines.

## Patterns

### Dual-write during migration
```typescript
// Migrating from PostgreSQL to DynamoDB
// Phase 1: Write to both, read from Postgres (source of truth)
async function createOrder(order: CreateOrderInput) {
  const result = await postgres.query(
    'INSERT INTO orders (id, user_id, total) VALUES ($1, $2, $3) RETURNING *',
    [order.id, order.userId, order.total]
  );

  // Async write to DynamoDB (best-effort during migration)
  try {
    await dynamodb.put({
      TableName: 'Orders',
      Item: { PK: `USER#${order.userId}`, SK: `ORDER#${order.id}`, ...order },
    });
  } catch (err) {
    logger.warn({ err, orderId: order.id }, 'DynamoDB write failed during migration');
    // Queue for retry, Postgres is source of truth
  }

  return result;
}

// Phase 2: Read from DynamoDB with Postgres fallback
// Phase 3: Write to DynamoDB only, stop Postgres writes
// Phase 4: Decommission Postgres tables
```

### Batch migration (large datasets)
```typescript
// Process in batches with cursor, not OFFSET
async function batchMigrate(batchSize = 1000, delayMs = 50) {
  let lastId = '';
  let totalProcessed = 0;

  while (true) {
    const batch = await db.query(
      `SELECT * FROM legacy_orders
       WHERE id > $1
       ORDER BY id
       LIMIT $2`,
      [lastId, batchSize]
    );

    if (batch.rows.length === 0) break;

    // Transform and insert into new table
    const transformed = batch.rows.map(row => ({
      id: row.id,
      userId: row.customer_id,          // column rename
      totalCents: Math.round(row.total * 100), // dollars to cents
      status: mapLegacyStatus(row.status),
      createdAt: row.created_at,
    }));

    await db.query(
      `INSERT INTO orders (id, user_id, total_cents, status, created_at)
       SELECT * FROM unnest($1::uuid[], $2::uuid[], $3::int[], $4::text[], $5::timestamptz[])
       ON CONFLICT (id) DO NOTHING`,
      [
        transformed.map(r => r.id),
        transformed.map(r => r.userId),
        transformed.map(r => r.totalCents),
        transformed.map(r => r.status),
        transformed.map(r => r.createdAt),
      ]
    );

    lastId = batch.rows[batch.rows.length - 1].id;
    totalProcessed += batch.rows.length;

    // Throttle to avoid overwhelming the database
    await new Promise(resolve => setTimeout(resolve, delayMs));

    if (totalProcessed % 10000 === 0) {
      logger.info({ totalProcessed, lastId }, 'Migration progress');
    }
  }

  logger.info({ totalProcessed }, 'Migration complete');
}
```

### Validation after migration
```typescript
// Spot-check migrated data for correctness
async function validateMigration(sampleSize = 1000): Promise<ValidationResult> {
  const samples = await postgres.query(
    'SELECT id FROM orders ORDER BY random() LIMIT $1',
    [sampleSize]
  );

  let matched = 0;
  let mismatched = 0;
  const errors: string[] = [];

  for (const row of samples.rows) {
    const pgOrder = await postgres.query('SELECT * FROM orders WHERE id = $1', [row.id]);
    const dynamoOrder = await dynamodb.get({ TableName: 'Orders', Key: { PK: `ORDER#${row.id}` } });

    if (deepEqual(normalize(pgOrder.rows[0]), normalize(dynamoOrder.Item))) {
      matched++;
    } else {
      mismatched++;
      errors.push(row.id);
    }
  }

  logger.info({ matched, mismatched, sampleSize }, 'Migration validation complete');
  return { matched, mismatched, errors };
}
```

## Anti-patterns
- Using OFFSET for batch processing -> gets slower with each batch (O(n) scan)
- No idempotency (`ON CONFLICT DO NOTHING`) -> duplicates if migration is re-run
- Mixing schema and data migrations in one step -> hard to rollback independently
- Validating only row count -> misses data corruption and transformation bugs
- Dual-write without a clear source of truth -> split-brain during incident

## Decision criteria
- **Dual-write**: migrating between database engines, need gradual transition with live traffic
- **Batch migration**: >1M rows to transform, can tolerate hours of background processing
- **Shadow read validation**: critical data where correctness must be proven before cutover

## Quick reference
```
Dual-write phases: write both -> read old -> read new -> write new only -> decommission
Batch size: 1000 rows, 50ms delay between batches
Cursor-based: WHERE id > $lastId ORDER BY id LIMIT $batch
Idempotency: ON CONFLICT (id) DO NOTHING on insert
Validate: random sample after backfill, before cutover
Log progress: every 10k rows with current cursor position
```
