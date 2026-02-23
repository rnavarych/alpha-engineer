# LLM Application Architecture Patterns

## When to load
Load when designing RAG systems, implementing AI agents, working with structured output, multimodal inputs, prompt engineering, or prompt security.

## AI System Design Framework

When advising on AI systems, evaluate:
- **Problem type**: Classification, generation, retrieval, extraction, agents, multimodal — each demands different architecture
- **Build vs buy**: Use hosted APIs by default; custom models only when domain specificity, data privacy, or cost at scale demands it — 95% of AI features don't need custom models
- **Latency requirements**: Real-time (<500ms TTFT) vs near-real-time (<3s) vs batch (minutes/hours)
- **Cost budget**: Model routing saves 10-60x — use the cheapest model that meets quality requirements
- **Data privacy**: Check DPA, data retention, training data usage for each provider; VPC isolation for sensitive data
- **Fallback strategies**: Always have a degraded path — cached responses, rule-based fallback, human escalation

## RAG (Retrieval-Augmented Generation)

The default pattern for knowledge-intensive applications. Cheaper, more auditable, and easier to update than fine-tuning.

- **Chunking strategies**: Fixed-size (simple, fast), semantic (paragraph/section boundaries), recursive (split on multiple delimiters), parent-child (small chunks for retrieval, large chunks for context)
- **Chunk sizing**: 256-512 tokens for precision retrieval, 512-1024 for contextual answers. Overlap 10-15% to prevent context loss at boundaries
- **Embedding models**: OpenAI text-embedding-3-small (cost-effective, 1536d), text-embedding-3-large (quality, 3072d), Cohere embed-v3 (multilingual), Voyage AI (code-specialized), BGE/Nomic (open-source)
- **Vector stores**: pgvector (PostgreSQL native, simple), Pinecone (managed, scale), Weaviate (hybrid search), Qdrant (Rust, fast), ChromaDB (prototyping), Milvus (large-scale)
- **Hybrid search**: Combine dense vectors (semantic) + sparse vectors (BM25/keyword) for best recall. Most production RAG systems use hybrid.
- **Reranking**: Cohere Rerank v3, cross-encoders (ms-marco-MiniLM) — rerank top-20 retrievals to top-5. Significant quality improvement for 10-50ms latency cost.
- **Evaluation**: Faithfulness (does answer match context?), relevance (is context relevant?), context recall (did we retrieve the right chunks?)

## AI Agents

Autonomous systems that plan, act, and observe in a loop.

- **ReAct pattern**: Reason → Act → Observe → repeat. The fundamental agent loop.
- **Tool use / function calling**: LLM decides intent; your code executes safely with auth checks. Never trust LLM output directly for DB writes or external actions.
- **Multi-agent orchestration**: Supervisor pattern (one agent routes to specialists), debate pattern (agents argue to consensus), pipeline pattern (sequential hand-off)
- **Frameworks**: LangGraph (stateful, graph-based), CrewAI (role-based teams), AutoGen (Microsoft, multi-agent), Semantic Kernel (Microsoft, .NET/Python), Haystack (pipelines)
- **Guardrails**: Input validation, output filtering, PII detection, content safety, max iteration limits, human-in-the-loop escalation
- **State management**: Short-term (conversation memory), long-term (persistent vector store), working memory (scratchpad for reasoning)

## Structured Output

- **JSON mode**: OpenAI, Anthropic — constrained output to valid JSON
- **Schema enforcement**: Zod (TypeScript), Pydantic (Python), Instructor library — parse and validate LLM output against schemas
- **Constrained decoding**: Grammar-based generation (llama.cpp, Outlines) — guarantee output matches a formal grammar
- **Retry strategies**: On schema validation failure, re-prompt with error context. Max 3 retries.

## Multimodal

- **Vision + text**: GPT-4o, Claude Sonnet/Opus (vision), Gemini 1.5/2.0 — document understanding, image analysis, OCR
- **Audio**: Whisper (OpenAI, open), Deepgram (fast, accurate), AssemblyAI (features-rich) — speech-to-text
- **Image generation**: DALL-E 3, Stable Diffusion 3/SDXL, Flux (Black Forest Labs), Midjourney API
- **Video understanding**: Gemini 1.5/2.0 (native video input, up to 1hr), GPT-4o (frame extraction)

## Prompt Engineering

**Techniques**
- **Zero-shot**: Direct instruction. Good for simple tasks with capable models.
- **Few-shot**: 3-5 examples in prompt. Significant quality boost for extraction, classification.
- **Chain-of-thought**: "Think step by step." Improves reasoning, math, logic tasks.
- **Self-consistency**: Sample multiple CoT paths, take majority answer. Better accuracy, higher cost.
- **Tree-of-thought**: Explore multiple reasoning branches, evaluate and prune. Best for complex problem-solving.

**Prompt management**
- Version control for prompts (git, prompt registries)
- A/B testing prompts in production
- Template engines (Jinja2, Handlebars) for dynamic prompt construction

**Prompt security**
- **Injection prevention**: Separate system/user content, input sanitization, instruction hierarchy
- **Jailbreak detection**: Pattern matching, classifier-based detection, Constitutional AI
- **Output validation**: Schema enforcement, content filters, PII redaction
- **Guardrails frameworks**: Guardrails AI, NeMo Guardrails (NVIDIA), Rebuff, LLM Guard
