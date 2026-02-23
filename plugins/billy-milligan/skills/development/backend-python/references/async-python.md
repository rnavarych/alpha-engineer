# Async Python Patterns

## asyncio Fundamentals

```python
import asyncio

# Gather — parallel execution of coroutines
async def fetch_dashboard_data(user_id: str):
    # BAD — sequential: 200ms + 300ms + 150ms = 650ms
    # user = await get_user(user_id)
    # orders = await get_orders(user_id)
    # stats = await get_stats(user_id)

    # GOOD — parallel: max(200, 300, 150) = 300ms
    user, orders, stats = await asyncio.gather(
        get_user(user_id),
        get_orders(user_id),
        get_stats(user_id),
    )
    return {"user": user, "orders": orders, "stats": stats}

# gather with return_exceptions — partial failure handling
results = await asyncio.gather(
    send_email(user),
    send_push(user),
    send_sms(user),
    return_exceptions=True,
)
for result in results:
    if isinstance(result, Exception):
        logger.error(f"Notification failed: {result}")
```

## aiohttp Client

```python
import aiohttp

async def fetch_multiple_apis(urls: list[str]) -> list[dict]:
    async with aiohttp.ClientSession(
        timeout=aiohttp.ClientTimeout(total=30, connect=5),
    ) as session:
        tasks = [fetch_url(session, url) for url in urls]
        return await asyncio.gather(*tasks, return_exceptions=True)

async def fetch_url(session: aiohttp.ClientSession, url: str) -> dict:
    async with session.get(url) as response:
        response.raise_for_status()
        return await response.json()

# Connection pooling — reuse session across requests
# Create session once at app startup, close on shutdown
class APIClient:
    def __init__(self):
        self._session: aiohttp.ClientSession | None = None

    async def start(self):
        self._session = aiohttp.ClientSession(
            connector=aiohttp.TCPConnector(limit=100),  # Max 100 connections
        )

    async def stop(self):
        if self._session:
            await self._session.close()

    async def get(self, url: str) -> dict:
        async with self._session.get(url) as resp:
            return await resp.json()
```

## concurrent.futures — Sync in Async Context

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor

# ThreadPoolExecutor — for blocking I/O (legacy sync libraries)
executor = ThreadPoolExecutor(max_workers=10)

async def call_sync_library(data: dict) -> dict:
    loop = asyncio.get_event_loop()
    # Runs sync function in thread pool — doesn't block event loop
    result = await loop.run_in_executor(
        executor,
        sync_heavy_library.process,
        data,
    )
    return result

# ProcessPoolExecutor — for CPU-bound work
process_executor = ProcessPoolExecutor(max_workers=4)

async def cpu_intensive_task(data: bytes) -> bytes:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        process_executor,
        compress_data,  # CPU-bound — runs in separate process
        data,
    )
```

## Structured Concurrency with TaskGroup

```python
# Python 3.11+ TaskGroup — structured concurrency
async def process_batch(items: list[dict]) -> list[dict]:
    results = []

    async with asyncio.TaskGroup() as tg:
        for item in items:
            task = tg.create_task(process_item(item))
            # All tasks must complete — if one raises, all are cancelled

    # Only reached if ALL tasks succeed
    return [task.result() for task in tg._tasks]

# Timeout with asyncio
async def fetch_with_timeout(url: str) -> dict:
    async with asyncio.timeout(5.0):  # Python 3.11+
        return await fetch_url(url)
    # Raises TimeoutError if exceeds 5 seconds
```

## Semaphore — Concurrency Control

```python
# Limit concurrent operations — prevent overwhelming external services
semaphore = asyncio.Semaphore(10)  # Max 10 concurrent

async def rate_limited_fetch(url: str) -> dict:
    async with semaphore:
        return await fetch_url(url)

# Process 1000 URLs with max 10 concurrent
async def fetch_all(urls: list[str]) -> list[dict]:
    tasks = [rate_limited_fetch(url) for url in urls]
    return await asyncio.gather(*tasks)
```

## Anti-Patterns
- `asyncio.gather` without `return_exceptions` — one failure cancels all
- Calling sync I/O in async function — blocks entire event loop
- No timeout on external calls — hangs forever if service is down
- Creating event loop inside async function — `asyncio.get_event_loop()` in wrong context

## Quick Reference
```
asyncio.gather: parallel coroutines, return_exceptions=True for resilience
aiohttp: reuse ClientSession, TCPConnector(limit=100)
ThreadPoolExecutor: blocking I/O (sync libs) — run_in_executor
ProcessPoolExecutor: CPU-bound — separate process
TaskGroup: structured concurrency (3.11+) — all-or-nothing
Semaphore: limit concurrent operations (rate limiting)
asyncio.timeout: 3.11+ timeout context manager
```
