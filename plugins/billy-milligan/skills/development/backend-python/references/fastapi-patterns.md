# FastAPI Patterns

## Application Structure with Lifespan

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.db import engine, init_db
from app.routers import orders, users

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown
    await engine.dispose()

app = FastAPI(
    title="Order Service",
    version="1.0.0",
    lifespan=lifespan,  # Not deprecated on_event
)

app.include_router(orders.router, prefix="/orders", tags=["orders"])
app.include_router(users.router, prefix="/users", tags=["users"])
```

## Dependency Injection

```python
from fastapi import Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from typing import AsyncGenerator

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """One session per request — commit on success, rollback on error."""
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
        raise HTTPException(401, "Invalid authorization header")
    token = authorization[7:]
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(401, "Token expired")
    user = await db.get(User, payload["sub"])
    if not user:
        raise HTTPException(401, "User not found")
    return user

# Usage — DI wires everything automatically
@router.post("/", response_model=OrderResponse, status_code=201)
async def create_order(
    body: OrderCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Order:
    order = Order(id=str(uuid4()), user_id=user.id, total=body.total)
    db.add(order)
    await db.flush()
    return order
```

## Pydantic v2 Schemas

```python
from pydantic import BaseModel, Field, field_validator, model_validator
from datetime import datetime

class OrderItemCreate(BaseModel):
    product_id: str = Field(pattern=r'^[0-9a-f-]{36}$')
    quantity: int = Field(ge=1, le=100)
    unit_price: float = Field(gt=0)

class OrderCreate(BaseModel):
    customer_id: str = Field(pattern=r'^[0-9a-f-]{36}$')
    items: list[OrderItemCreate] = Field(min_length=1)
    notes: str | None = Field(default=None, max_length=500)

    @field_validator('items')
    @classmethod
    def unique_products(cls, items: list[OrderItemCreate]) -> list[OrderItemCreate]:
        ids = [i.product_id for i in items]
        if len(ids) != len(set(ids)):
            raise ValueError("Duplicate products in order")
        return items

class OrderResponse(BaseModel):
    id: str
    status: str
    total: float
    created_at: datetime

    model_config = {"from_attributes": True}  # ORM object -> Pydantic
```

## Background Tasks vs Celery

```python
from fastapi import BackgroundTasks

# FastAPI BackgroundTasks — lightweight, in-process
# Use for: email notifications, analytics events, webhook calls
@router.post("/orders/{order_id}/confirm")
async def confirm_order(
    order_id: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
) -> dict:
    order = await db.get(Order, order_id)
    order.status = "confirmed"
    background_tasks.add_task(send_confirmation_email, order.email, order_id)
    return {"status": "confirmed"}

# Celery — heavy, persistent, retryable
# Use for: PDF generation, image processing, batch operations
from celery import Celery
celery_app = Celery("tasks", broker=os.environ["REDIS_URL"])

@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def generate_invoice(self, order_id: str):
    try:
        pdf = render_invoice(order_id)
        upload_to_s3(pdf, f"invoices/{order_id}.pdf")
    except Exception as exc:
        raise self.retry(exc=exc)
```

## Async Middleware

```python
from starlette.middleware.base import BaseHTTPMiddleware
import time, uuid

class RequestContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
        start = time.perf_counter()

        response = await call_next(request)

        duration = time.perf_counter() - start
        response.headers["x-request-id"] = request_id
        response.headers["x-response-time"] = f"{duration:.3f}s"
        return response

app.add_middleware(RequestContextMiddleware)
```

## Anti-Patterns
- Mixing sync DB calls in async routes — blocks the event loop
- Using `on_event("startup")` — deprecated, use lifespan context manager
- Mutable default arguments — `def fn(tags: list = [])` shares state across calls
- Creating engine inside route handler — connection pool per request

## Quick Reference
```
Lifespan: asynccontextmanager, replaces on_event
DI: Depends() for db sessions, auth, config
Pydantic v2: model_config = {"from_attributes": True}
BackgroundTasks: lightweight, in-process (email, webhooks)
Celery: heavy, persistent, retryable (PDF, batch, external API)
field_validator: @classmethod for single field validation
model_validator: mode='after' for cross-field validation
```
