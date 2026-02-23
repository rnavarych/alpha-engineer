# Database Testing and Seeding

## When to load
Load when setting up database tests with Testcontainers, writing database factories, or managing seed scripts.

## Testcontainers

### Node.js (TypeScript)

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql'

let container: StartedPostgreSqlContainer

beforeAll(async () => {
  container = await new PostgreSqlContainer('postgres:16-alpine').start()
  process.env.DATABASE_URL = container.getConnectionUri()
  await migrate(process.env.DATABASE_URL) // run actual migrations
})

afterAll(() => container.stop())

// Each test in a transaction that rolls back
beforeEach(() => db.$executeRaw`BEGIN`)
afterEach(() => db.$executeRaw`ROLLBACK`)
```

### Python

```python
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        run_migrations(pg.get_connection_url())
        yield pg

@pytest.fixture
async def session(postgres):
    async with async_session() as s:
        async with s.begin():
            yield s
            await s.rollback()
```

### Go

```go
func TestMain(m *testing.M) {
    ctx := context.Background()
    req := testcontainers.ContainerRequest{
        Image:        "postgres:16-alpine",
        Env:          map[string]string{"POSTGRES_PASSWORD": "test"},
        ExposedPorts: []string{"5432/tcp"},
        WaitingFor:   wait.ForListeningPort("5432/tcp"),
    }
    pg, _ := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req, Started: true,
    })
    // run migrations, set DSN, run tests
    os.Exit(m.Run())
}
```

## pg_tmp (Fast Postgres Test Databases)

```bash
# pg_tmp creates a temporary Postgres instance per test suite
# much faster than Testcontainers for local development
eval $(pg_tmp)
createdb myapp_test
DATABASE_URL="$PGURL/myapp_test" go test ./...
```

## Database Factories

### TypeScript — fishery + faker

```typescript
import { Factory } from 'fishery'
import { faker } from '@faker-js/faker'

const userFactory = Factory.define<User>(({ sequence }) => ({
  id: faker.string.uuid(),
  email: faker.internet.email(),
  name: faker.person.fullName(),
  tenantId: faker.string.uuid(),
  createdAt: new Date(),
}))

// Usage
const user = userFactory.build({ email: 'specific@example.com' })
const users = userFactory.buildList(10)
const dbUser = await userFactory.create({}, { transientParams: { db } })
```

### Python — factory_boy

```python
import factory
from factory.alchemy import SQLAlchemyModelFactory

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session = db_session

    id = factory.LazyFunction(uuid.uuid4)
    email = factory.Faker('email')
    name = factory.Faker('name')
    tenant_id = factory.LazyFunction(uuid.uuid4)
```

## Seeding Best Practices

- Maintain seed scripts for development and testing environments
- Use factories/fixtures for test data generation
- Never seed production databases with test data
- Make seeds idempotent (safe to run multiple times): use upserts
- Separate reference data seeds (countries, currencies, roles) from test data seeds
- Order seeds to respect foreign key constraints
