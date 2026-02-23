# Data Types, Naming Conventions, and Anti-Patterns

## When to load
Load when making data type decisions (money, timestamps, JSON, enums), establishing naming conventions, or identifying and fixing schema anti-patterns (EAV, polymorphic associations, god tables).

## Data Type Best Practices

| Data | Recommended Type | Avoid | Reason |
|------|-----------------|-------|--------|
| **Money** | `DECIMAL(12,2)` or `BIGINT` (cents) | `FLOAT`, `DOUBLE` | Floating point precision errors |
| **Timestamps** | `TIMESTAMPTZ` (PG), `DATETIME` (MySQL) | `TIMESTAMP` without TZ | Timezone confusion |
| **IP addresses** | `INET` (PG), `VARBINARY(16)` (MySQL) | `VARCHAR(45)` | Efficient storage and operations |
| **Email** | `CITEXT` (PG) or `VARCHAR(254)` | `TEXT` without constraint | Max email length is 254 per RFC 5321 |
| **JSON data** | `JSONB` (PG), `JSON` (MySQL 8+) | `TEXT` + parse in app | Indexable, validatable |
| **Enums** | `VARCHAR` with CHECK or lookup table | Native ENUM type | ENUMs are hard to modify |
| **Country** | `CHAR(2)` (ISO 3166-1 alpha-2) | `VARCHAR(100)` for country name | Standardized, compact |
| **Currency** | `CHAR(3)` (ISO 4217) | `VARCHAR` for currency name | Standardized |
| **Phone** | `VARCHAR(20)` (E.164 format) | `BIGINT` | Leading zeros, formatting |

### PostgreSQL-Specific Types
```sql
CREATE DOMAIN email AS CITEXT CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
CREATE DOMAIN positive_amount AS DECIMAL(12,2) CHECK (VALUE > 0);

-- Range type with exclusion constraint (no overlapping reservations)
CREATE TABLE reservations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id INT NOT NULL,
    during TSTZRANGE NOT NULL,
    EXCLUDE USING GIST (room_id WITH =, during WITH &&)
);
```

## Naming Conventions

| Element | Convention | Example | Anti-Pattern |
|---------|-----------|---------|-------------|
| **Tables** | Plural, snake_case | `order_items` | `OrderItem`, `tbl_order_item` |
| **Columns** | Singular, snake_case | `created_at` | `CreatedAt`, `dtCreated` |
| **Primary keys** | `id` | `orders.id` | `order_id`, `OrderID` |
| **Foreign keys** | `{referenced_table_singular}_id` | `orders.customer_id` | `custID` |
| **Indexes** | `idx_{table}_{columns}` | `idx_orders_customer_id` | `index1` |
| **Unique constraints** | `unq_{table}_{columns}` | `unq_users_email` | `unique1` |
| **Booleans** | `is_` or `has_` prefix | `is_active`, `has_verified` | `active` |
| **Timestamps** | `_at` suffix | `created_at`, `updated_at` | `creation_date` |

```sql
-- Auto-update updated_at (PostgreSQL)
CREATE OR REPLACE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
-- MySQL equivalent
-- updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

## Anti-Patterns to Avoid

### Entity-Attribute-Value (EAV)
```sql
-- ANTI-PATTERN: no type safety, impossible to query efficiently
CREATE TABLE attributes (entity_id INT, attribute_name VARCHAR(100), attribute_value TEXT);

-- BETTER: JSONB for flexible attributes
ALTER TABLE products ADD COLUMN attributes JSONB DEFAULT '{}';
-- Or table-per-type inheritance for known types
```

### Polymorphic Associations
```sql
-- ANTI-PATTERN: commentable_type + commentable_id, no FK constraint possible
-- BETTER: exclusive arc with CHECK constraint
CREATE TABLE comments (
    id BIGINT PRIMARY KEY,
    post_id BIGINT REFERENCES posts(id),
    photo_id BIGINT REFERENCES photos(id),
    video_id BIGINT REFERENCES videos(id),
    body TEXT,
    CHECK (
        (post_id IS NOT NULL)::int +
        (photo_id IS NOT NULL)::int +
        (video_id IS NOT NULL)::int = 1
    )
);
```

### God Tables
```
ANTI-PATTERN: Single table with 100+ columns, many NULL (billing, shipping, preferences, settings, subscription all in users table)
BETTER: Vertical split into focused tables
- users (core identity: id, email, name, created_at)
- user_profiles (bio, avatar, preferences)
- user_addresses (type, street, city, country)
- user_settings (notification, privacy, display)
- user_subscriptions (plan, billing, payment_method)
```

### Other Anti-Patterns

| Anti-Pattern | Problem | Solution |
|-------------|---------|----------|
| Missing timestamps | Cannot audit or debug | Always add `created_at`, `updated_at` |
| Over-indexing | Slow writes, wasted space | Index only WHERE, JOIN, ORDER BY columns |
| Missing foreign keys | Orphaned data | Always define FK constraints in OLTP |
| VARCHAR(255) everywhere | Wrong size estimation | Use appropriate lengths or TEXT |
| Business logic in triggers | Hidden, hard to test | Keep logic in application layer |
| No check constraints | Invalid data enters | Add CHECK for enums, ranges, positive values |
