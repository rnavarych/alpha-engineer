---
name: backend-python
description: Python backend patterns — FastAPI, Django, SQLAlchemy, async patterns, Pydantic v2
allowed-tools: Read, Grep, Glob, Bash
---

# Backend Python Skill

## Core Principles
- **Async throughout**: Mixing sync and async in FastAPI causes thread pool starvation.
- **Lifespan context manager**: Use for startup/shutdown — `on_event` is deprecated.
- **Pydantic for all I/O**: Request bodies, response models, config — single source of truth.
- **One pool per process**: Connection pools are singletons, never per-request.
- **Type annotations everywhere**: Python is typed now; use it.

## References
- `references/fastapi-patterns.md` — DI, Pydantic v2, background tasks, async middleware
- `references/django-patterns.md` — Models, DRF, signals, migrations, admin customization
- `references/sqlalchemy-patterns.md` — Session management, eager/lazy loading, async, Alembic
- `references/async-python.md` — asyncio, aiohttp, concurrent.futures, structured concurrency

## Scripts
- `scripts/detect-python-stack.sh` — Reads requirements.txt/pyproject.toml to identify stack
