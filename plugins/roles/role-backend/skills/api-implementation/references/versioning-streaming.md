# API Versioning and Streaming Responses

## When to load
Load when designing API versioning strategy or implementing streaming endpoints (SSE, chunked JSON for AI completions, real-time event feeds).

## API Versioning

- **URL path versioning** (preferred): `/api/v1/users`, `/api/v2/users`
- Maintain backward compatibility within a major version
- Deprecate old versions with `Sunset` and `Deprecation` headers and migration guides
- Use content negotiation as an alternative: `Accept: application/vnd.api.v2+json`
- Never remove fields from responses without a major version bump
- Additive changes (new optional fields) are backward compatible and do not require a new version
- For GraphQL: use `@deprecated(reason: "...")` directive; avoid versioned schemas

## Server-Sent Events (SSE)

### Hono SSE

```typescript
import { streamSSE } from 'hono/streaming'

app.get('/api/events', (c) => {
  return streamSSE(c, async (stream) => {
    while (true) {
      const event = await eventBus.next()
      await stream.writeSSE({
        data: JSON.stringify(event),
        event: event.type,
        id: event.id,
      })
    }
  })
})
```

### Express / Node.js SSE

```typescript
app.get('/api/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')

  const send = (data: object, event?: string) => {
    if (event) res.write(`event: ${event}\n`)
    res.write(`data: ${JSON.stringify(data)}\n\n`)
  }

  const interval = setInterval(() => send({ ts: Date.now() }, 'heartbeat'), 30000)
  req.on('close', () => clearInterval(interval))
})
```

## Chunked JSON Streaming

### FastAPI — AI completions streaming

```python
from fastapi.responses import StreamingResponse

@app.get("/api/completions")
async def stream_completion(prompt: str):
    async def generate():
        async for chunk in llm.stream(prompt):
            yield f"data: {json.dumps({'content': chunk})}\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream")
```

### Node.js — ReadableStream response

```typescript
app.get('/api/stream', async (c) => {
  const { readable, writable } = new TransformStream()
  const writer = writable.getWriter()
  const encoder = new TextEncoder()

  ;(async () => {
    for await (const chunk of dataSource) {
      await writer.write(encoder.encode(JSON.stringify(chunk) + '\n'))
    }
    await writer.close()
  })()

  return new Response(readable, {
    headers: { 'Content-Type': 'application/x-ndjson' },
  })
})
```

## NDJSON Streaming Pattern

Newline-delimited JSON is useful for long-running operations that produce multiple results:

```typescript
// Producer: write each record as a JSON line
response.write(JSON.stringify(record) + '\n')

// Consumer: parse line by line
for await (const line of response.body.pipeThrough(new TextDecoderStream())) {
  if (line.trim()) {
    const record = JSON.parse(line)
    processRecord(record)
  }
}
```

Use cases:
- AI token streaming (each token as a JSON line)
- Bulk export endpoints (stream rows without buffering full result)
- Long-running job progress events
- Database cursor pagination over HTTP
