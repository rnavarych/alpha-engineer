# Database Patterns

## pgx Connection Pool

```go
import (
    "github.com/jackc/pgx/v5/pgxpool"
)

func initDB(ctx context.Context) (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
    if err != nil {
        return nil, fmt.Errorf("parse db config: %w", err)
    }

    config.MaxConns = 20                          // Max connections
    config.MinConns = 2                           // Keep minimum alive
    config.MaxConnLifetime = time.Hour            // Recycle connections
    config.MaxConnIdleTime = 30 * time.Minute     // Close idle
    config.HealthCheckPeriod = time.Minute        // Verify periodically
    config.ConnConfig.ConnectTimeout = 5 * time.Second

    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, fmt.Errorf("create pool: %w", err)
    }

    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("ping database: %w", err)
    }

    return pool, nil
}
```

## Queries with pgx

```go
// Single row
func (r *OrderRepo) FindByID(ctx context.Context, id string) (*Order, error) {
    row := r.db.QueryRow(ctx,
        `SELECT id, user_id, status, total, created_at
         FROM orders WHERE id = $1`, id)

    var o Order
    err := row.Scan(&o.ID, &o.UserID, &o.Status, &o.Total, &o.CreatedAt)
    if err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return nil, ErrNotFound
        }
        return nil, fmt.Errorf("FindByID: %w", err)
    }
    return &o, nil
}

// Multiple rows
func (r *OrderRepo) ListByUser(ctx context.Context, userID string, limit int) ([]Order, error) {
    rows, err := r.db.Query(ctx,
        `SELECT id, user_id, status, total, created_at
         FROM orders WHERE user_id = $1
         ORDER BY created_at DESC LIMIT $2`, userID, limit)
    if err != nil {
        return nil, fmt.Errorf("ListByUser query: %w", err)
    }
    defer rows.Close()

    var orders []Order
    for rows.Next() {
        var o Order
        if err := rows.Scan(&o.ID, &o.UserID, &o.Status, &o.Total, &o.CreatedAt); err != nil {
            return nil, fmt.Errorf("ListByUser scan: %w", err)
        }
        orders = append(orders, o)
    }
    return orders, rows.Err()
}
```

## sqlx — Struct Scanning

```go
import "github.com/jmoiron/sqlx"

type Order struct {
    ID        string    `db:"id"`
    UserID    string    `db:"user_id"`
    Status    string    `db:"status"`
    Total     float64   `db:"total"`
    CreatedAt time.Time `db:"created_at"`
}

func (r *OrderRepo) ListByUser(ctx context.Context, userID string) ([]Order, error) {
    var orders []Order
    err := r.db.SelectContext(ctx, &orders,
        `SELECT id, user_id, status, total, created_at
         FROM orders WHERE user_id = $1
         ORDER BY created_at DESC`, userID)
    if err != nil {
        return nil, fmt.Errorf("ListByUser: %w", err)
    }
    return orders, nil
}

// Named queries
func (r *OrderRepo) Create(ctx context.Context, o *Order) error {
    _, err := r.db.NamedExecContext(ctx,
        `INSERT INTO orders (id, user_id, status, total)
         VALUES (:id, :user_id, :status, :total)`, o)
    return err
}
```

## Transactions

```go
func (r *OrderRepo) CreateWithItems(ctx context.Context, order *Order, items []OrderItem) error {
    tx, err := r.db.Begin(ctx)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback(ctx) // No-op if committed

    _, err = tx.Exec(ctx,
        `INSERT INTO orders (id, user_id, status, total) VALUES ($1, $2, $3, $4)`,
        order.ID, order.UserID, order.Status, order.Total)
    if err != nil {
        return fmt.Errorf("insert order: %w", err)
    }

    for _, item := range items {
        _, err = tx.Exec(ctx,
            `INSERT INTO order_items (id, order_id, product_id, quantity, unit_price)
             VALUES ($1, $2, $3, $4, $5)`,
            item.ID, order.ID, item.ProductID, item.Quantity, item.UnitPrice)
        if err != nil {
            return fmt.Errorf("insert item: %w", err)
        }
    }

    return tx.Commit(ctx)
}
```

## Migrations with golang-migrate

```bash
# Install
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Create migration
migrate create -ext sql -dir migrations -seq add_orders_table

# Run migrations
migrate -database "$DATABASE_URL" -path migrations up

# Rollback one step
migrate -database "$DATABASE_URL" -path migrations down 1
```

```sql
-- migrations/000001_add_orders_table.up.sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    total NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_created ON orders (user_id, created_at DESC);

-- migrations/000001_add_orders_table.down.sql
DROP TABLE IF EXISTS orders;
```

## Anti-Patterns
- `defer rows.Close()` missing — connection leak
- Not checking `rows.Err()` after iteration — silent errors
- Ignoring context in DB calls — queries can't be cancelled
- String interpolation in queries — SQL injection (`$1` not `"` + id + `"`)

## Quick Reference
```
pgx: pool.QueryRow/Query/Exec — always pass ctx
sqlx: struct scanning with db tags, NamedExec for structs
Pool: MaxConns=20, MinConns=2, HealthCheckPeriod=1m
Transaction: Begin + defer Rollback + Commit
Migrations: golang-migrate — up.sql/down.sql pairs
Rows: always defer rows.Close(), check rows.Err()
Params: $1, $2 (pgx) or ? (sqlx with Rebind)
```
