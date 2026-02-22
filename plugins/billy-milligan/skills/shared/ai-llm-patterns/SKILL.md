---
name: ai-llm-patterns
description: |
  AI/LLM integration patterns: Anthropic SDK streaming with TypeScript, RAG architecture
  (chunking, embedding, vector search with pgvector), tool use / function calling,
  model selection guide (Haiku vs Sonnet vs Opus), prompt caching, structured output with
  Zod, token cost management. Use when building AI features, RAG pipelines, AI agents.
allowed-tools: Read, Grep, Glob
---

# AI/LLM Integration Patterns

## When to Use This Skill
- Building AI features with Claude / Anthropic SDK
- Implementing RAG (Retrieval-Augmented Generation)
- Using tool use / function calling patterns
- Choosing the right Claude model for the task
- Managing token costs and prompt caching

## Core Principles

1. **Model selection matters for cost** — Haiku is 10× cheaper than Sonnet; Sonnet is 5× cheaper than Opus; use the smallest model that can do the task
2. **Streaming for user experience** — start showing text immediately; never make users wait for full response
3. **Tool use for deterministic operations** — LLM decides what to do; your code does it safely; never trust LLM output directly for DB writes
4. **Prompt caching for repeated context** — system prompts, documents, RAG context: cache if >1024 tokens
5. **RAG chunk size matters** — too small (50 tokens) = no context; too large (2000 tokens) = irrelevant context dilutes relevance

---

## Patterns ✅

### Anthropic SDK — Streaming Response

```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

// Streaming: start showing text as it generates
export async function streamChatResponse(
  userMessage: string,
  onChunk: (text: string) => void,
): Promise<string> {
  let fullText = '';

  const stream = await client.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: 'You are a helpful assistant for our e-commerce platform.',
    messages: [{ role: 'user', content: userMessage }],
  });

  for await (const chunk of stream) {
    if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
      onChunk(chunk.delta.text);
      fullText += chunk.delta.text;
    }
  }

  const finalMessage = await stream.finalMessage();
  // Log usage for cost tracking
  console.log({
    inputTokens: finalMessage.usage.input_tokens,
    outputTokens: finalMessage.usage.output_tokens,
  });

  return fullText;
}

// Server-Sent Events endpoint for streaming to browser
app.get('/api/chat/stream', async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const question = req.query.q as string;

  await streamChatResponse(question, (chunk) => {
    res.write(`data: ${JSON.stringify({ text: chunk })}\n\n`);
  });

  res.write('data: [DONE]\n\n');
  res.end();
});
```

### Tool Use (Function Calling)

```typescript
// Tool use: Claude decides when to call a tool; your code executes it
// Pattern: Claude reasons about intent → tool call → you execute safely → Claude continues

const tools: Anthropic.Tool[] = [
  {
    name: 'get_order_status',
    description: 'Get the current status and details of an order by order ID',
    input_schema: {
      type: 'object',
      properties: {
        order_id: {
          type: 'string',
          description: 'The order ID to look up (format: ord_xxx)',
        },
      },
      required: ['order_id'],
    },
  },
  {
    name: 'cancel_order',
    description: 'Cancel an order that is in pending or processing status',
    input_schema: {
      type: 'object',
      properties: {
        order_id: { type: 'string' },
        reason: { type: 'string', description: 'Reason for cancellation' },
      },
      required: ['order_id', 'reason'],
    },
  },
];

export async function runAgentLoop(
  userId: string,
  userMessage: string,
): Promise<string> {
  const messages: Anthropic.MessageParam[] = [
    { role: 'user', content: userMessage },
  ];

  while (true) {
    const response = await client.messages.create({
      model: 'claude-haiku-4-5-20251001',  // Haiku for simple customer service
      max_tokens: 1024,
      system: `You are a customer service agent. Help users with their orders.
               User ID: ${userId}. Only access orders belonging to this user.`,
      tools,
      messages,
    });

    if (response.stop_reason === 'end_turn') {
      // Extract text response
      const text = response.content
        .filter(b => b.type === 'text')
        .map(b => (b as Anthropic.TextBlock).text)
        .join('');
      return text;
    }

    if (response.stop_reason === 'tool_use') {
      // Execute tool calls
      const toolResults: Anthropic.ToolResultBlockParam[] = [];

      for (const block of response.content) {
        if (block.type !== 'tool_use') continue;

        let result: string;
        try {
          result = await executeTool(block.name, block.input as Record<string, string>, userId);
        } catch (err) {
          result = `Error: ${String(err)}`;
        }

        toolResults.push({
          type: 'tool_result',
          tool_use_id: block.id,
          content: result,
        });
      }

      // Continue conversation with tool results
      messages.push({ role: 'assistant', content: response.content });
      messages.push({ role: 'user', content: toolResults });
    }
  }
}

async function executeTool(
  name: string,
  input: Record<string, string>,
  userId: string,
): Promise<string> {
  switch (name) {
    case 'get_order_status': {
      const order = await orderService.findById(input.order_id, userId);
      if (!order) return 'Order not found or does not belong to you';
      return JSON.stringify({ id: order.id, status: order.status, total: order.total });
    }
    case 'cancel_order': {
      await orderService.cancel(input.order_id, userId, input.reason);
      return `Order ${input.order_id} has been cancelled`;
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}
```

### RAG with pgvector

```typescript
// RAG: Retrieval-Augmented Generation
// Chunk documents → embed → store → retrieve relevant chunks → include in prompt

import { openai } from '@ai-sdk/openai';  // For embeddings

// 1. Chunk document (overlap prevents context loss at boundaries)
function chunkText(text: string, chunkSize = 512, overlap = 50): string[] {
  const words = text.split(' ');
  const chunks: string[] = [];
  let i = 0;

  while (i < words.length) {
    const chunk = words.slice(i, i + chunkSize).join(' ');
    chunks.push(chunk);
    i += chunkSize - overlap;
  }
  return chunks;
}

// 2. Embed and store
async function indexDocument(documentId: string, text: string): Promise<void> {
  const chunks = chunkText(text);

  for (const [index, chunk] of chunks.entries()) {
    const embeddingResponse = await client.post('https://api.openai.com/v1/embeddings', {
      model: 'text-embedding-3-small',
      input: chunk,
    });
    const embedding = embeddingResponse.data.data[0].embedding as number[];

    await db.insert(documentChunks).values({
      documentId,
      chunkIndex: index,
      content: chunk,
      embedding: sql`${JSON.stringify(embedding)}::vector`,  // pgvector
    });
  }
}

// 3. Retrieve relevant chunks (cosine similarity with pgvector)
async function retrieveContext(query: string, topK = 5): Promise<string[]> {
  const queryEmbedding = await getEmbedding(query);

  const results = await db.execute(sql`
    SELECT content, 1 - (embedding <=> ${JSON.stringify(queryEmbedding)}::vector) AS similarity
    FROM document_chunks
    ORDER BY embedding <=> ${JSON.stringify(queryEmbedding)}::vector
    LIMIT ${topK}
  `);

  return results.rows.map(r => r.content as string);
}

// 4. Generate answer with context
async function answerWithRAG(question: string): Promise<string> {
  const contextChunks = await retrieveContext(question);
  const context = contextChunks.join('\n\n---\n\n');

  const response = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: 'Answer questions based only on the provided context. If the answer is not in the context, say so.',
    messages: [{
      role: 'user',
      content: `Context:\n${context}\n\nQuestion: ${question}`,
    }],
  });

  return (response.content[0] as Anthropic.TextBlock).text;
}
```

### Prompt Caching for Cost Reduction

```typescript
// Cache system prompts and large context that doesn't change per request
// Minimum 1024 tokens to be eligible for caching
// Cache TTL: 5 minutes (extended with each use)

const response = await client.messages.create({
  model: 'claude-sonnet-4-6',
  max_tokens: 1024,
  system: [
    {
      type: 'text',
      text: longSystemPrompt,  // e.g., 5000-token prompt with company context
      cache_control: { type: 'ephemeral' },  // Cache this block
    },
  ],
  messages: [
    {
      role: 'user',
      content: [
        {
          type: 'text',
          text: largeDocumentContext,  // e.g., 10000 tokens of product docs
          cache_control: { type: 'ephemeral' },  // Cache this too
        },
        {
          type: 'text',
          text: userQuestion,  // Only this changes per request — not cached
        },
      ],
    },
  ],
});

// First request: full input tokens charged
// Subsequent requests within 5 min: cached tokens at 10% of normal price
// For 15,000-token prompt used 100×/hour: 90% cost reduction on input tokens
```

### Model Selection Guide

```
claude-haiku-4-5-20251001 (Haiku):
  Use for: classification, simple Q&A, customer service routing, data extraction
  Cost: ~$0.25 input / $1.25 output per million tokens
  Speed: fastest (<1s for most responses)
  Avoid: complex reasoning, multi-step analysis, code generation

claude-sonnet-4-6 (Sonnet):
  Use for: general assistant, code generation, content creation, analysis
  Cost: ~$3 input / $15 output per million tokens
  Speed: fast (1-3s)
  Default choice for most features

claude-opus-4-6 (Opus):
  Use for: complex reasoning, research synthesis, nuanced judgment
  Cost: ~$15 input / $75 output per million tokens
  Speed: slower (3-10s)
  Use only when Sonnet cannot handle the task quality requirement
```

---

## Anti-Patterns ❌

### Using Opus for Simple Tasks
**What it is**: Using `claude-opus-4-6` for "summarize this order" or "classify this support ticket."
**What breaks**: 60× cost multiplier vs Haiku for a task Haiku handles perfectly.
**Fix**: Test with Haiku first. Upgrade to Sonnet if quality is insufficient. Use Opus only for complex analysis that demonstrably requires it.

### Trusting LLM Output for DB Writes
**What it is**: Passing LLM-generated SQL or data directly into database operations.
**What breaks**: Prompt injection can make LLM output malicious content. LLM can hallucinate IDs.
**Fix**: Use tool use pattern — LLM calls tools with validated inputs; your code executes with authorization checks.

### No Streaming for Long Responses
**What it is**: Waiting for complete LLM response before sending anything to client.
**What breaks**: 5-10 second wait with blank screen for a 500-token response.
**Fix**: Stream with SSE or WebSocket. Start showing text within 500ms.

---

## Quick Reference

```
Default model: claude-sonnet-4-6 for most features
Haiku: simple tasks, high volume, cost-sensitive
Opus: complex analysis only — 60× cost of Haiku
Streaming: always for user-facing text; SSE for web, WebSocket for realtime
Tool use: LLM decides intent; your code executes safely with auth checks
RAG chunks: 256-512 tokens, 10-15% overlap
Embeddings: text-embedding-3-small (cost/performance balance)
pgvector: <=> for cosine distance, <#> for inner product
Prompt caching: min 1024 tokens, 5-min TTL, 90% cost reduction on cached tokens
Tokens to cost: 1000 tokens ≈ 750 words ≈ $0.003 (Sonnet input)
```
