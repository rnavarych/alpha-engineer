# SQLAlchemy Patterns

## Async Engine & Session

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy import String, Numeric, ForeignKey

DATABASE_URL = os.environ["DATABASE_URL"].replace(
    "postgresql://", "postgresql+asyncpg://"
)

engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,           # Max connections per process
    max_overflow=10,        # Extra connections under load
    pool_pre_ping=True,     # Verify connection alive before use
    pool_recycle=3600,      # Recycle after 1h
)

AsyncSessionFactory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Prevents lazy load after commit
)
```

## Model Declaration (2.0 Style)

```python
class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)

    orders: Mapped[list["Order"]] = relationship(back_populates="user", lazy="selectin")

class Order(Base):
    __tablename__ = "orders"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    total: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

    user: Mapped["User"] = relationship(back_populates="orders")
    items: Mapped[list["OrderItem"]] = relationship(back_populates="order", lazy="selectin")
```

## Eager vs Lazy Loading

```python
from sqlalchemy.orm import selectinload, joinedload
from sqlalchemy import select

# BAD — lazy loading triggers N+1 (one query per order's items)
async def get_orders_bad(db: AsyncSession):
    result = await db.execute(select(Order))
    orders = result.scalars().all()
    for order in orders:
        print(order.items)  # N additional queries!

# GOOD — eager loading with selectinload (2 queries total)
async def get_orders_good(db: AsyncSession, user_id: str):
    stmt = (
        select(Order)
        .where(Order.user_id == user_id)
        .options(
            selectinload(Order.items),           # Batch load items
            joinedload(Order.user),               # JOIN for single FK
        )
        .order_by(Order.created_at.desc())
        .limit(20)
    )
    result = await db.execute(stmt)
    return result.scalars().unique().all()

# selectinload: separate SELECT ... WHERE id IN (...) — best for collections
# joinedload: SQL JOIN — best for single FK relationships
# subqueryload: subquery — for deep nesting
```

## Transactions

```python
# Implicit transaction via session context manager
async def create_order(db: AsyncSession, data: OrderCreate) -> Order:
    order = Order(id=str(uuid4()), user_id=data.user_id, total=data.total)
    db.add(order)

    for item in data.items:
        db.add(OrderItem(order_id=order.id, **item.model_dump()))

    await db.flush()  # Get IDs without committing
    return order
    # Commit happens in the dependency (get_db)

# Explicit nested transaction (savepoint)
async def transfer_with_validation(db: AsyncSession, from_id: str, to_id: str, amount: float):
    async with db.begin_nested():  # SAVEPOINT
        from_account = await db.get(Account, from_id, with_for_update=True)
        if from_account.balance < amount:
            raise InsufficientFundsError()
        from_account.balance -= amount

        to_account = await db.get(Account, to_id, with_for_update=True)
        to_account.balance += amount
    # RELEASE SAVEPOINT — outer transaction continues
```

## Alembic Migrations

```bash
# Initialize
alembic init alembic

# Generate migration from model changes
alembic revision --autogenerate -m "add shipping_method to orders"

# Run migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1
```

```python
# alembic/env.py — async configuration
from sqlalchemy.ext.asyncio import async_engine_from_config

def run_migrations_online():
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
```

## Anti-Patterns
- Lazy loading in async context — raises `MissingGreenlet` error
- `expire_on_commit=True` (default) — triggers lazy load after commit
- Creating engine per request — exhausts connection pool
- Missing `with_for_update` on balance/inventory updates — race conditions

## Quick Reference
```
Engine: pool_size=20, pool_pre_ping=True, one per process
Session: expire_on_commit=False for async
Eager loading: selectinload (collections), joinedload (single FK)
Mapped types: Mapped[str], mapped_column(String)
Transactions: session context manager, begin_nested() for savepoints
Alembic: --autogenerate for schema diffs, upgrade head to apply
```
