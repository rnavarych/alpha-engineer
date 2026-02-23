# LLM Operations (LLMOps)

## When to load
Load when productionizing AI features, implementing observability, cost management, or model evaluation.

## Production Architecture

```
Client Request
    │
    ▼
┌──────────────┐
│  API Gateway  │  Rate limiting, auth
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  LLM Router  │  Model selection, fallback, load balancing
└──────┬───────┘
       │
       ├──→ Claude API (primary)
       ├──→ OpenAI API (fallback)
       └──→ Local model (cost optimization)
       │
       ▼
┌──────────────┐
│  Cache Layer  │  Semantic cache for repeated queries
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Observability│  Logging, tracing, cost tracking
└──────────────┘
```

## LLM Gateway / Router

```typescript
interface LLMConfig {
  provider: 'anthropic' | 'openai';
  model: string;
  maxTokens: number;
  temperature: number;
  timeout: number;
  costPer1KInput: number;
  costPer1KOutput: number;
}

const MODEL_CONFIG: Record<string, LLMConfig> = {
  'high-quality': {
    provider: 'anthropic',
    model: 'claude-sonnet-4-6',
    maxTokens: 4096,
    temperature: 0.3,
    timeout: 30000,
    costPer1KInput: 0.003,
    costPer1KOutput: 0.015,
  },
  'fast-cheap': {
    provider: 'anthropic',
    model: 'claude-haiku-4-5-20251001',
    maxTokens: 2048,
    temperature: 0,
    timeout: 10000,
    costPer1KInput: 0.001,
    costPer1KOutput: 0.005,
  },
};

async function llmCall(
  tier: string,
  messages: Message[],
  options?: Partial<LLMConfig>
): Promise<LLMResponse> {
  const config = { ...MODEL_CONFIG[tier], ...options };
  const startTime = Date.now();

  try {
    const response = await callProvider(config, messages);

    // Track metrics
    await trackLLMCall({
      tier,
      model: config.model,
      inputTokens: response.usage.input_tokens,
      outputTokens: response.usage.output_tokens,
      latencyMs: Date.now() - startTime,
      cost: calculateCost(response.usage, config),
    });

    return response;
  } catch (error) {
    // Fallback to next tier
    if (tier === 'high-quality') {
      return llmCall('fast-cheap', messages, options);
    }
    throw error;
  }
}
```

## Cost Management

```
Cost tracking per request:
  Input:  tokens * cost_per_1K_input / 1000
  Output: tokens * cost_per_1K_output / 1000
  Cache:  cache_read_tokens * cache_read_cost / 1000

Cost reduction strategies:
  1. Prompt caching (Claude): cache system prompts, save 90% on repeated prefixes
  2. Semantic caching: cache LLM responses for similar queries
  3. Model routing: use Haiku for simple tasks, Sonnet for complex
  4. Prompt optimization: shorter prompts = fewer input tokens
  5. Max tokens: set reasonable limits (don't default to max)
  6. Batch API: 50% discount for non-urgent requests (Claude Batch API)
```

```typescript
// Semantic cache with Redis
async function cachedLLMCall(query: string, tier: string): Promise<string> {
  const queryEmbedding = await embed(query);

  // Check cache: find similar queries
  const cached = await redis.call(
    'FT.SEARCH', 'llm_cache',
    `*=>[KNN 1 @embedding $vec AS score]`,
    'PARAMS', '2', 'vec', Buffer.from(new Float32Array(queryEmbedding).buffer),
    'RETURN', '2', 'response', 'score',
    'DIALECT', '2'
  );

  if (cached.score < 0.05) { // cosine distance < 0.05 = very similar
    return cached.response;
  }

  const response = await llmCall(tier, [{ role: 'user', content: query }]);

  // Store in cache with 1h TTL
  await cacheLLMResponse(query, queryEmbedding, response.text, 3600);

  return response.text;
}
```

## Evaluation & Testing

```typescript
// LLM evaluation framework
interface EvalCase {
  input: string;
  expectedOutput?: string;      // exact match
  expectedContains?: string[];  // must contain
  expectedNotContains?: string[]; // must not contain
  rubric?: string;              // LLM-as-judge criteria
}

async function runEval(cases: EvalCase[], model: string): Promise<EvalResult> {
  const results = await Promise.all(cases.map(async (testCase) => {
    const response = await llmCall('high-quality', [
      { role: 'user', content: testCase.input },
    ]);

    const checks = {
      containsExpected: testCase.expectedContains?.every(
        s => response.text.includes(s)
      ) ?? true,
      excludesForbidden: testCase.expectedNotContains?.every(
        s => !response.text.includes(s)
      ) ?? true,
    };

    // LLM-as-judge for subjective quality
    let judgeScore: number | null = null;
    if (testCase.rubric) {
      judgeScore = await llmJudge(testCase.input, response.text, testCase.rubric);
    }

    return { testCase, response: response.text, checks, judgeScore };
  }));

  return {
    total: results.length,
    passed: results.filter(r => r.checks.containsExpected && r.checks.excludesForbidden).length,
    avgJudgeScore: average(results.map(r => r.judgeScore).filter(Boolean)),
    failures: results.filter(r => !r.checks.containsExpected || !r.checks.excludesForbidden),
  };
}
```

## Observability

```typescript
// Structured logging for LLM calls
interface LLMLog {
  requestId: string;
  model: string;
  tier: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens?: number;
  latencyMs: number;
  costUsd: number;
  status: 'success' | 'error' | 'fallback';
  error?: string;
  // Do NOT log: full prompts/responses (PII risk)
  // DO log: prompt template name, truncated input hash
}

// Key metrics to track:
// - P50/P95/P99 latency per model tier
// - Token usage per endpoint/user
// - Cost per request/user/day
// - Error rate and fallback rate
// - Cache hit rate
// - Eval scores over time (regression detection)
```

## Guardrails

```typescript
// Input/output validation
async function safeLLMCall(userInput: string): Promise<string> {
  // Input guardrails
  if (userInput.length > 10000) throw new Error('Input too long');
  if (containsPII(userInput)) {
    userInput = redactPII(userInput); // mask SSN, email, phone
  }

  const response = await llmCall('high-quality', [
    { role: 'user', content: userInput },
  ]);

  // Output guardrails
  if (containsPII(response.text)) {
    return redactPII(response.text);
  }

  return response.text;
}
```

## Anti-patterns
- No cost tracking → surprise bills, no optimization signal
- Logging full prompts with user data → GDPR/PII violation
- Single model for all tasks → over-paying for simple tasks
- No fallback → single provider outage = total failure
- No evaluation suite → can't detect regressions on prompt changes
- No rate limiting → one user can exhaust API quota

## Quick reference
```
Architecture: gateway → router → cache → provider → observability
Model routing: Haiku for simple, Sonnet for complex, Opus for critical
Cost: track per request, cache similar queries, batch non-urgent
Caching: prompt caching (90% savings on system prompts), semantic cache
Evaluation: automated test suite, LLM-as-judge for subjective quality
Observability: latency, tokens, cost, error rate, cache hit rate
Guardrails: PII redaction, input length limits, output validation
Fallback: primary → secondary provider, degrade gracefully
Batch API: 50% discount for non-real-time workloads
```
