# Neon and Turso

## When to load
Load when working with Neon (serverless PostgreSQL with branching) or Turso/libSQL (edge SQLite with embedded replicas). Covers CLI setup, scale-to-zero configuration, CI/CD branch automation, and embedded replica patterns.

## Neon

### CLI and Branch Management
```bash
npm install -g neonctl
neonctl projects create --name my-app --region aws-us-east-1
neonctl branches create --name staging --parent main
neonctl branches create --name preview/pr-42 --parent main
neonctl branches list
neonctl connection-string --branch main
neonctl branches delete preview/pr-42
```

### Scale-to-Zero and Drizzle ORM
```typescript
import { neon, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';

const sql = neon(process.env.DATABASE_URL);
const db = drizzle(sql);

const orders = await db
  .select()
  .from(ordersTable)
  .where(eq(ordersTable.status, 'pending'));
```

### Auto-Scaling Config
```bash
neonctl endpoints update ep-xxx \
  --min-cu 0.25 \
  --max-cu 4 \
  --suspend-timeout 300
# Append -pooler to hostname for built-in PgBouncer (transaction mode)
```

### CI/CD Branch per PR
```yaml
name: Preview Database
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  create-neon-branch:
    runs-on: ubuntu-latest
    steps:
      - uses: neondatabase/create-branch-action@v5
        id: create-branch
        with:
          project_id: ${{ secrets.NEON_PROJECT_ID }}
          branch_name: preview/pr-${{ github.event.pull_request.number }}
          api_key: ${{ secrets.NEON_API_KEY }}
      - name: Run Migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ steps.create-branch.outputs.db_url }}
```

## Turso / libSQL

### CLI Setup and Regions
```bash
curl -sSfL https://get.tur.so/install.sh | bash
turso db create my-app --group default
turso group locations add default lhr
turso group locations add default nrt
turso db show my-app --url
turso db tokens create my-app
```

### Embedded Replicas
```typescript
import { createClient } from '@libsql/client';

const client = createClient({
  url: 'file:local-replica.db',
  syncUrl: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
  syncInterval: 60,
});

await client.sync();
const result = await client.execute('SELECT * FROM orders WHERE status = ?', ['pending']);
await client.execute('INSERT INTO orders (customer, amount) VALUES (?, ?)', ['alice', 99.99]);
await client.sync();
```

### Database-per-Tenant via Platform API
```bash
curl -X POST "https://api.turso.tech/v1/organizations/my-org/databases" \
  -H "Authorization: Bearer $TURSO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "tenant-abc", "group": "default"}'
```
