---
name: ai-system-design
description: |
  AI system architecture patterns: ML pipeline design, model serving infrastructure,
  feature store architecture, A/B testing for models, evaluation frameworks, RAG system
  design, AI agent architecture, responsible AI guardrails, GPU infrastructure planning.
  Viktor's AI domain. Use when designing AI/ML systems, choosing model serving strategy,
  building RAG pipelines, designing evaluation frameworks, planning AI infrastructure.
allowed-tools: Read, Grep, Glob
---

# AI System Design Patterns

## When to Use This Skill
- Designing ML pipeline architecture (training, evaluation, deployment)
- Choosing model serving infrastructure (real-time vs batch vs serverless)
- Building production RAG systems (chunking, retrieval, generation)
- Designing AI agent architectures (tool use, multi-agent, orchestration)
- Planning evaluation and monitoring for AI systems
- Making build vs buy decisions for AI capabilities
- Planning GPU infrastructure and cost optimization

## Core Principles

1. **Start with API, not model** — use hosted models (Anthropic, OpenAI, Bedrock) before training your own; 95% of AI features don't need custom models; the other 5% should prove it with a failed API experiment first
2. **Evaluation before deployment** — if you can't measure it, don't ship it; golden sets, automated evals, human review; "I tried it and it seemed good" is not an evaluation strategy
3. **RAG before fine-tuning** — fine-tuning is expensive ($$$), slow (hours/days), and hard to update; RAG is dynamic, auditable, cheaper, and you get citations for free
4. **Guardrails are not optional** — input validation, output filtering, PII detection, content safety; one hallucinated medical advice or leaked PII = front-page PR disaster
5. **Cost is a first-class architecture concern** — model routing (cheap model first), caching, batching; GPT-4o at 100k requests/day costs more than your entire database infrastructure

---

## Patterns ✅

### Build vs Buy Decision Matrix

```
Signal                    | Build (train/fine-tune)              | Buy (hosted API)
─────────────────────────────────────────────────────────────────────────────────────
Data sensitivity          | PII/PHI that can't leave your infra  | Non-sensitive or DPA-covered
Accuracy requirement      | >95% on domain-specific tasks        | 80-95% acceptable
Request volume            | >1M requests/day (cost optimization) | <100k requests/day
Team ML expertise         | Dedicated ML engineers               | No ML team
Time to market            | 3-6 months acceptable                | Need it in weeks
Domain specificity        | Highly specialized (medical, legal)   | General-purpose tasks
Model control             | Need deterministic behavior          | Acceptable variability
─────────────────────────────────────────────────────────────────────────────────────
Default: Buy. Switch to Build only when multiple signals align.
```

### RAG System Architecture

```typescript
// Production RAG pipeline: Ingestion → Retrieval → Generation

// 1. Ingestion pipeline (runs offline / on document update)
interface IngestionPipeline {
  // Step 1: Parse documents (PDF, HTML, Markdown, DOCX)
  parse(source: DocumentSource): ParsedDocument[];

  // Step 2: Chunk with overlap (prevents context loss at boundaries)
  chunk(doc: ParsedDocument, config: {
    strategy: 'fixed' | 'semantic' | 'recursive';  // semantic = split on paragraphs/sections
    chunkSize: number;    // 256-512 tokens for precision, 512-1024 for context
    overlap: number;      // 10-15% of chunk size
  }): Chunk[];

  // Step 3: Embed chunks (batch for throughput)
  embed(chunks: Chunk[], model: string): EmbeddedChunk[];
  // Models: text-embedding-3-small ($0.02/1M tokens, good enough for most)
  //         text-embedding-3-large ($0.13/1M tokens, when quality matters)

  // Step 4: Store in vector DB
  store(chunks: EmbeddedChunk[], index: VectorIndex): void;
  // Options: pgvector (simple), Pinecone (managed), Qdrant (fast)
}

// 2. Retrieval pipeline (runs per query, <200ms budget)
async function retrieve(query: string, config: RetrievalConfig): Promise<Context> {
  // Step 1: Embed the query
  const queryVector = await embed(query);

  // Step 2: Hybrid search — dense (semantic) + sparse (keyword/BM25)
  const denseResults = await vectorStore.search(queryVector, { topK: 20 });
  const sparseResults = await bm25Index.search(query, { topK: 20 });

  // Step 3: Reciprocal Rank Fusion (merge dense + sparse results)
  const merged = reciprocalRankFusion(denseResults, sparseResults, { k: 60 });

  // Step 4: Rerank top-20 to top-5 (significant quality boost, 10-50ms cost)
  // Cohere Rerank v3 or cross-encoder/ms-marco-MiniLM-L-12-v2
  const reranked = await reranker.rerank(query, merged.slice(0, 20), { topK: 5 });

  return { chunks: reranked, sources: reranked.map(r => r.metadata.source) };
}

// 3. Generation with citations
async function generateAnswer(question: string, context: Context): Promise<Answer> {
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: `Answer questions based ONLY on the provided context.
             If the answer is not in the context, say "I don't have enough information."
             Always cite sources using [Source: filename] format.`,
    messages: [{
      role: 'user',
      content: `Context:\n${context.chunks.map(c => c.content).join('\n\n---\n\n')}\n\nQuestion: ${question}`,
    }],
  });

  return {
    text: response.content[0].text,
    sources: context.sources,  // Auditable — user can verify
    tokens: response.usage,    // Track cost
  };
}
```

### Model Serving Architecture

```
┌─────────────────────────────────────────────────┐
│ Tier 1: API Gateway                              │
│ - Rate limiting (per user, per feature)          │
│ - Authentication (API key, JWT, IAM)             │
│ - Request validation (schema, size limits)       │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Tier 2: Model Router                             │
│ - Task classification → model selection          │
│ - A/B testing traffic split                      │
│ - Fallback chain (primary → secondary → cached)  │
│ - Cost-based routing (cheapest that fits)        │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Tier 3: Inference Layer                          │
│ - Hosted API (Anthropic, OpenAI, Bedrock)        │
│ - Self-hosted (vLLM, TGI on GPU instances)       │
│ - Batch pipeline (for non-realtime)              │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Tier 4: Post-Processing                          │
│ - Output validation (schema, length, format)     │
│ - Content safety filter (toxicity, PII)          │
│ - Citation extraction and verification           │
│ - Response formatting (markdown, JSON)           │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Tier 5: Observability                            │
│ - Request tracing (Langfuse, LangSmith)          │
│ - Cost tracking (model × tokens per request)     │
│ - Latency monitoring (TTFT, total, p95)          │
│ - Quality metrics (user feedback, eval scores)   │
└─────────────────────────────────────────────────┘
```

### Model Router (Cost Optimization)

```typescript
// Route to cheapest model that can handle the task
// Tier 1: Haiku/Flash (<$0.001/req) — classification, extraction, simple Q&A
// Tier 2: Sonnet/GPT-4o-mini (<$0.01/req) — general assistant, code, content
// Tier 3: Opus/GPT-4o (<$0.10/req) — complex reasoning, research, multi-step

interface ModelRouter {
  route(request: AIRequest): ModelConfig;
}

function classifyComplexity(input: string): 'simple' | 'moderate' | 'complex' {
  // Heuristics (fast, no LLM call):
  const wordCount = input.split(' ').length;
  const hasCode = /```/.test(input);
  const hasMultiStep = /\b(then|after that|next|also|additionally)\b/i.test(input);
  const hasAnalysis = /\b(compare|analyze|evaluate|trade-?offs|pros and cons)\b/i.test(input);

  if (wordCount < 50 && !hasCode && !hasMultiStep && !hasAnalysis) return 'simple';
  if (hasAnalysis || (hasCode && hasMultiStep)) return 'complex';
  return 'moderate';
}

const modelTiers: Record<string, ModelConfig> = {
  simple:   { model: 'claude-haiku-4-5-20251001', maxTokens: 512 },
  moderate: { model: 'claude-sonnet-4-6', maxTokens: 1024 },
  complex:  { model: 'claude-opus-4-6', maxTokens: 4096 },
};

// Fallback chain: if primary model fails, try next tier
async function routeWithFallback(request: AIRequest): Promise<AIResponse> {
  const complexity = classifyComplexity(request.input);
  const tiers = ['simple', 'moderate', 'complex'];
  const startIndex = tiers.indexOf(complexity);

  for (let i = startIndex; i < tiers.length; i++) {
    try {
      return await callModel(modelTiers[tiers[i]], request);
    } catch (err) {
      if (i === tiers.length - 1) throw err; // Last tier, no fallback
      console.warn(`Model ${tiers[i]} failed, falling back to ${tiers[i + 1]}`);
    }
  }
  throw new Error('All model tiers exhausted');
}
```

### AI Agent Architecture

```typescript
// ReAct Agent: Reason → Act → Observe → Repeat
// With safety limits and human escalation

interface AgentConfig {
  maxIterations: number;        // Hard limit: 10
  humanEscalationAt: number;    // Escalate after 5 failed tool calls
  tools: Tool[];
  model: string;
}

async function runAgent(
  task: string,
  config: AgentConfig,
): Promise<AgentResult> {
  const messages: Message[] = [{ role: 'user', content: task }];
  let iterations = 0;
  let failedToolCalls = 0;

  while (iterations < config.maxIterations) {
    iterations++;

    const response = await anthropic.messages.create({
      model: config.model,
      max_tokens: 4096,
      system: `You are an AI agent. Use the provided tools to accomplish tasks.
               Think step by step. If stuck after 3 attempts, explain what's blocking you.`,
      tools: config.tools,
      messages,
    });

    // Agent finished reasoning
    if (response.stop_reason === 'end_turn') {
      return { success: true, result: extractText(response), iterations };
    }

    // Agent wants to use tools
    if (response.stop_reason === 'tool_use') {
      const toolResults = [];

      for (const block of response.content.filter(b => b.type === 'tool_use')) {
        try {
          const result = await executeTool(block.name, block.input);
          toolResults.push({ tool_use_id: block.id, content: result });
        } catch (err) {
          failedToolCalls++;
          toolResults.push({ tool_use_id: block.id, content: `Error: ${err.message}`, is_error: true });

          // Human escalation: too many failures means the agent is stuck
          if (failedToolCalls >= config.humanEscalationAt) {
            return {
              success: false,
              result: 'Agent stuck — escalating to human',
              iterations,
              reason: 'too_many_tool_failures',
            };
          }
        }
      }

      messages.push({ role: 'assistant', content: response.content });
      messages.push({ role: 'user', content: toolResults });
    }
  }

  return { success: false, result: 'Max iterations reached', iterations, reason: 'max_iterations' };
}
```

### Evaluation Pipeline

```typescript
// Automated evaluation: golden set + LLM-as-judge
// Run in CI on every prompt/model change

interface GoldenExample {
  input: string;
  expectedOutput: string;
  category: string;  // 'factual' | 'reasoning' | 'creative' | 'safety'
  metadata?: Record<string, unknown>;
}

async function evaluateGoldenSet(
  goldenSet: GoldenExample[],
  pipeline: AIPipeline,
): Promise<EvalReport> {
  const results = await Promise.all(
    goldenSet.map(async (example) => {
      const actual = await pipeline.run(example.input);

      // Metric 1: Semantic similarity (embedding cosine distance)
      const similarity = await cosineSimilarity(
        await embed(actual),
        await embed(example.expectedOutput),
      );

      // Metric 2: LLM-as-judge (Claude evaluates quality)
      const judgment = await anthropic.messages.create({
        model: 'claude-sonnet-4-6',
        max_tokens: 256,
        messages: [{
          role: 'user',
          content: `Rate the quality of the AI response on a scale of 1-5.
                    Question: ${example.input}
                    Expected: ${example.expectedOutput}
                    Actual: ${actual}
                    Score (1-5) and brief justification:`,
        }],
      });

      return {
        input: example.input,
        category: example.category,
        similarity,
        llmScore: parseLLMScore(judgment),
        pass: similarity > 0.8 && parseLLMScore(judgment) >= 4,
      };
    }),
  );

  const passRate = results.filter(r => r.pass).length / results.length;
  const avgSimilarity = results.reduce((s, r) => s + r.similarity, 0) / results.length;

  return {
    passRate,
    avgSimilarity,
    results,
    // Deployment gate: block if pass rate drops >5% from baseline
    deploymentAllowed: passRate >= 0.85,
  };
}
```

---

## Anti-Patterns ❌

### Fine-Tuning When RAG Would Work
**What it is**: Training a custom model to "know" your documentation, product specs, or domain data.
**What breaks**: Model goes stale when docs update — you have to retrain. Training costs $100-$10,000. Hallucinations increase if training data quality is poor. Cannot cite sources ("I just know it" is not auditable). Model size increases, serving cost increases.
**Fix**: Use RAG. Update documents in real-time. Get citations for free. Fine-tune only for style, format, or behavior — never for knowledge. Knowledge goes in the retrieval layer.

### No Evaluation Framework
**What it is**: Shipping AI features with "I tried a few examples and it seemed fine."
**What breaks**: Prompt change regresses quality on edge cases you didn't test. No baseline for comparison — you can't tell if the new model is better or worse. Cannot detect quality degradation in production until users complain. No deployment gate — every change is a coin flip.
**Fix**: Build golden set (100+ curated examples across categories). Automate evaluation in CI. Block deployment if scores drop >5% from baseline. Add human review for ambiguous cases. Monitor in production with user feedback signals.

### Ignoring AI Costs at Scale
**What it is**: Building everything with GPT-4o or Claude Opus because "it gives the best results."
**What breaks**: $50/day prototype becomes $50,000/month in production. Single customer conversation costs $2-5. Management sees the bill, panics, kills the feature.
**Fix**: Model routing: classify task complexity → use cheapest model that works. Prompt caching: 90% input cost reduction for repeated context (Anthropic). Batching: 50% discount for non-realtime (Batch API). Budget per feature: estimate `daily_requests × avg_tokens × price_per_token` before launch.

### Raw LLM Output to Users Without Guardrails
**What it is**: No output validation, no content filtering, no PII redaction. Just pipe model output straight to the user.
**What breaks**: Hallucinated medical advice, financial recommendations without disclaimers. Exposed PII from training data or context. Offensive or inappropriate content. Prompt injection attacks ("ignore previous instructions and..."). One bad output = screenshot on Twitter = PR disaster.
**Fix**: Schema validation (Zod/Pydantic) for structured outputs. Content safety filter (OpenAI Moderation API, Azure Content Safety). PII detection and redaction (Presidio, Comprehend). Hallucination mitigation (RAG with citations, confidence scoring). Human escalation for high-stakes outputs (medical, financial, legal).

---

## Quick Reference

```
Default approach: hosted API (Anthropic/OpenAI/Bedrock), not custom model
RAG chunk size: 256-512 tokens (precision), 512-1024 (context), 10-15% overlap
Embedding model: text-embedding-3-small (cost), text-embedding-3-large (quality)
Reranker: Cohere Rerank v3 or cross-encoder (ms-marco-MiniLM-L-12-v2)
Vector store: pgvector (simple), Pinecone (managed), Qdrant (fast)
Hybrid search: dense (semantic) + sparse (BM25), merge with RRF
Eval golden set: 100+ examples, automated in CI, block deploy if score drops >5%
Model routing: Haiku/Flash <$0.001/req → Sonnet <$0.01/req → Opus <$0.10/req
Agent max iterations: 10 hard limit, human escalation at 5 failed tool calls
GPU serving: vLLM for open models, 4-bit quantization = 75% memory reduction
Cost formula: daily_requests × avg_input_tokens × input_price + daily_requests × avg_output_tokens × output_price
Safety: content filter + PII redaction + schema validation + human escalation
```
