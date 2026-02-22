---
name: backend-python
description: |
  Python backend patterns: FastAPI with async SQLAlchemy 2.0, Pydantic v2 validators,
  lifespan handler for startup/shutdown, dependency injection, background tasks vs Celery,
  pytest fixtures, connection pooling, type annotations. Use when building Python APIs.
allowed-tools: Read, Grep, Glob
---

# Python Backend Patterns

## When to Use This Skill
- Building FastAPI applications with async SQLAlchemy
- Configuring database connections for async Python
- Pydantic v2 schema design with validators
- Background task patterns (FastAPI vs Celery)
- Python testing with pytest and fixtures

## Core Principles

1. **Async throughout** — mixing sync and async in FastAPI causes thread pool starvation
2. **Lifespan context manager** — startup/shutdown, not deprecated on_event
3. **Pydantic for all I/O boundaries** — request bodies, response models, config
4. **Connection pools via asyncpg/asyncio** — one pool per process, not per request
5. **Type annotations everywhere** — Python is typed now; use it

---

## Patterns ✅

### FastAPI Application Structure

```python
# app/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.db import engine, init_db
from app.routers import orders, users

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize connections
    await init_db()
    yield
    # Shutdown: close connections
    await engine.dispose()

app = FastAPI(
    title="Order Service",
    version="1.0.0",
    lifespan=lifespan,  # Replaces deprecated @app.on_event
)

app.include_router(orders.router, prefix="/orders", tags=["orders"])
app.include_router(users.router, prefix="/users", tags=["users"])

@app.get("/health")
async def health() -> dict:
    return {"status": "healthy", "version": "1.0.0"}
```

### Async SQLAlchemy 2.0

```python
# app/db.py
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
import os

DATABASE_URL = os.environ["DATABASE_URL"].replace("postgresql://", "postgresql+asyncpg://")

# Engine created once — connection pool managed automatically
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,           # Max connections per process
    max_overflow=10,        # Extra connections allowed under load
    pool_pre_ping=True,     # Verify connection alive before use
    pool_recycle=3600,      # Recycle connections after 1h
    echo=os.environ.get("SQL_ECHO", "false").lower() == "true",
)

AsyncSessionFactory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Don't expire objects after commit (avoids lazy loads)
)

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

class Base(DeclarativeBase):
    pass

# app/models/order.py
from sqlalchemy import String, Numeric, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db import Base
import enum

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Order(Base):
    __tablename__ = "orders"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    status: Mapped[OrderStatus] = mapped_column(SAEnum(OrderStatus), default=OrderStatus.PENDING)
    total: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
```

### Pydantic v2 Schemas

```python
# app/schemas/order.py
from pydantic import BaseModel, field_validator, model_validator, Field
from datetime import datetime
from typing import Annotated
import uuid

# Annotated types for reuse
PositiveDecimal = Annotated[float, Field(gt=0, decimal_places=2)]
UUID4 = Annotated[str, Field(pattern=r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')]

class OrderItemCreate(BaseModel):
    product_id: UUID4
    quantity: int = Field(ge=1, le=100)
    unit_price: PositiveDecimal

class OrderCreate(BaseModel):
    customer_id: UUID4
    items: list[OrderItemCreate] = Field(min_length=1)
    notes: str | None = Field(default=None, max_length=500)

    @field_validator('items')
    @classmethod
    def validate_unique_products(cls, items: list[OrderItemCreate]) -> list[OrderItemCreate]:
        product_ids = [item.product_id for item in items]
        if len(product_ids) != len(set(product_ids)):
            raise ValueError("Duplicate products in order")
        return items

    @model_validator(mode='after')
    def validate_total(self) -> 'OrderCreate':
        total = sum(item.unit_price * item.quantity for item in self.items)
        if total > 100_000:
            raise ValueError(f"Order total {total} exceeds maximum allowed")
        return self

class OrderResponse(BaseModel):
    id: str
    customer_id: str
    status: str
    total: float
    created_at: datetime

    model_config = {"from_attributes": True}  # Allow ORM object → Pydantic
```

### FastAPI Dependency Injection

```python
# app/dependencies.py
from fastapi import Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from app.db import AsyncSessionFactory
from typing import AsyncGenerator
import jwt

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Database session dependency — one session per request."""
    async with AsyncSessionFactory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

async def get_current_user(
    authorization: str = Header(...),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    token = authorization[7:]
    try:
        payload = jwt.decode(token, os.environ["JWT_SECRET"], algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = await db.get(User, payload["sub"])
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# Route using dependencies
@router.post("/", response_model=OrderResponse, status_code=201)
async def create_order(
    body: OrderCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Order:
    order = Order(
        id=str(uuid.uuid4()),
        customer_id=current_user.id,
        status=OrderStatus.PENDING,
        total=sum(item.unit_price * item.quantity for item in body.items),
    )
    db.add(order)
    await db.flush()  # Get ID without committing (commit happens in get_db)
    return order
```

### Background Tasks: FastAPI vs Celery

```python
# FastAPI BackgroundTasks: for lightweight, fast tasks
# (email notifications, analytics events, webhook calls)
@router.post("/orders/{order_id}/confirm")
async def confirm_order(
    order_id: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
) -> dict:
    order = await db.get(Order, order_id)
    order.status = OrderStatus.CONFIRMED
    # Schedule email after response sent (non-blocking)
    background_tasks.add_task(send_confirmation_email, order.customer_email, order_id)
    return {"status": "confirmed"}

# Celery: for heavy, long-running, or retry-needed tasks
# (PDF generation, external API calls, batch processing)
# app/tasks.py
from celery import Celery
app_celery = Celery("tasks", broker=os.environ["REDIS_URL"])

@app_celery.task(bind=True, max_retries=3, default_retry_delay=60)
def generate_invoice(self, order_id: str):
    try:
        # Heavy operation — runs in separate worker process
        pdf = render_invoice_pdf(order_id)
        upload_to_s3(pdf, f"invoices/{order_id}.pdf")
    except Exception as exc:
        raise self.retry(exc=exc)  # Retry with delay
```

---

## Anti-Patterns ❌

### Mixing Sync and Async
**What it is**: Calling a synchronous blocking function from an async route.
**What breaks**: FastAPI runs async handlers in the event loop. Sync DB call blocks the event loop. All other requests wait. 1 slow sync call → entire server appears slow.
**Fix**: Either use `await asyncio.get_event_loop().run_in_executor(None, sync_fn)` or ensure all I/O is async.

### Creating Engine Per Request
**What it is**: `engine = create_async_engine(DATABASE_URL)` inside a route handler.
**What breaks**: New connection pool per request. Connections never cleaned up. PostgreSQL runs out of connections. OOM on the DB.
**Fix**: One engine at module level, created at app startup.

### Mutable Default Arguments
```python
# Wrong — mutable default is shared across calls
def create_tags(tags: list = []):
    tags.append("default")  # Modifies the shared default list
    return tags

# Correct
def create_tags(tags: list | None = None):
    if tags is None:
        tags = []
    tags.append("default")
    return tags
```

### Using on_event (Deprecated)
```python
# Wrong — deprecated, unreliable for cleanup
@app.on_event("startup")
async def startup():
    await init_db()

# Correct — use lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await engine.dispose()
```

---

## Quick Reference

```
Engine pool_size: 20 (one pool per process)
pool_pre_ping: True — always (avoids stale connection errors)
expire_on_commit: False — prevents lazy load errors after commit
Pydantic v2 config: model_config = {"from_attributes": True} for ORM
Lifespan: asynccontextmanager, not deprecated on_event
BackgroundTasks: lightweight, fast (email, analytics)
Celery: heavy, long-running, needs retry (PDF, batch, external API)
Mixing sync/async: use run_in_executor if you must call sync code
```
