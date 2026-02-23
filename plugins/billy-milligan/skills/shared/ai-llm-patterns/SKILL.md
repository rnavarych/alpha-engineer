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

## References available
- `references/prompt-engineering.md` — streaming with SSE, model selection guide (Haiku/Sonnet/Opus), prompt caching, structured output with Zod
- `references/rag-architecture.md` — chunking strategy, embedding with text-embedding-3-small, pgvector cosine search, retrieval pipeline
- `references/llm-ops.md` — tool use / agent loop pattern, cost tracking, token budgeting, multi-model routing, error handling
