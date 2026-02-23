---
name: ai-saas-platforms
description: |
  DEPRECATED — merged into shared/ai-llm-patterns.
  AI platform patterns are now in:
  - shared/ai-llm-patterns/references/llm-ops.md (model routing, cost, observability)
  - shared/ai-llm-patterns/references/prompt-engineering.md (prompting, structured output)
  - shared/ai-llm-patterns/references/rag-architecture.md (RAG, embeddings, vector DB)
allowed-tools: Read, Grep, Glob
---

# AI SaaS Platforms

## When to Use This Skill
- Choosing between AI providers for a feature
- Integrating AI APIs (OpenAI, Anthropic, Google, AWS Bedrock, Azure OpenAI)
- Estimating and optimizing AI API costs
- Building provider abstraction for multi-model strategy
- Migrating from one AI provider to another
- Evaluating new AI platforms and models

## Core Principles

1. **Abstract the provider, not the capability** — wrap API calls in a service layer, but don't build a universal "AI provider" interface; capabilities differ too much (prompt caching = Anthropic only, 1M context = Gemini only, JSON mode behavior differs); abstract at the feature level
2. **Cost per feature, not cost per token** — estimate what a single user action costs end-to-end; $0.003/request vs $0.30/request = 100x difference; multiply by daily volume before launch or die of invoice shock
3. **Latency = UX** — TTFT (time to first token) matters more than throughput; Groq 100ms TTFT vs Opus 3-5s TTFT; always stream for user-facing responses
4. **Data privacy is a deal-breaker, not a nice-to-have** — check DPA, data retention, training data usage for each provider; Azure OpenAI and AWS Bedrock offer VPC-level isolation; some providers use API data for training (check the fine print)
5. **Lock-in is real but manageable** — function calling schemas, prompt formats, token counts all differ between providers; budget 2-4 weeks for provider migration per feature; the abstraction layer helps but doesn't eliminate migration cost

---

## Patterns ✅

### Provider Cost Comparison (Real Numbers)

```
Per 1M tokens (input / output), approximate as of 2025:

┌─────────────────────────────────────────────────────────────────────────────┐
│ Tier 1 — Cheap & Fast (classification, extraction, simple Q&A)             │
│                                                                             │
│   Claude 3.5 Haiku:      $0.25  / $1.25     (best instruction-following)   │
│   GPT-4o-mini:           $0.15  / $0.60     (cheapest with JSON mode)      │
│   Gemini 1.5 Flash:      $0.075 / $0.30     (cheapest overall)            │
│   Mistral Small:         $0.10  / $0.30     (EU data residency)           │
│   Llama 3.1 8B (Groq):   ~$0.05 / $0.08    (fastest, self-hostable)      │
├─────────────────────────────────────────────────────────────────────────────┤
│ Tier 2 — Balanced (general assistant, code gen, content creation)          │
│                                                                             │
│   Claude Sonnet 4:       $3.00  / $15.00    (best code, tool use)         │
│   GPT-4o:                $2.50  / $10.00    (multimodal, structured out)   │
│   Gemini 1.5 Pro:        $1.25  / $5.00     (1M context, cheapest tier 2) │
│   Mistral Large 2:       $2.00  / $6.00     (EU compliance)              │
├─────────────────────────────────────────────────────────────────────────────┤
│ Tier 3 — Premium (complex reasoning, research, nuanced judgment)          │
│                                                                             │
│   Claude Opus 4:         $15.00 / $75.00    (best reasoning quality)      │
│   o1/o3 (OpenAI):        $15.00 / $60.00    (chain-of-thought reasoning)  │
│   Gemini 2.0 Pro:        TBD                (multimodal reasoning)        │
└─────────────────────────────────────────────────────────────────────────────┘

Cost example: Customer support chatbot, 10,000 conversations/day, avg 500 input + 200 output tokens:
  Haiku:  10k × (500×$0.25 + 200×$1.25) / 1M = $3.75/day  ($112/month)
  Sonnet: 10k × (500×$3.00 + 200×$15.0) / 1M = $45.00/day ($1,350/month)
  Opus:   10k × (500×$15.0 + 200×$75.0) / 1M = $225.00/day ($6,750/month)
```

### Provider Abstraction Layer

```typescript
// Abstract at the SERVICE level, not the provider level
// Each service wraps one AI capability with the best provider for that job

interface TextGenerationService {
  generate(prompt: string, options?: GenerateOptions): Promise<GenerateResult>;
  stream(prompt: string, options?: GenerateOptions): AsyncIterable<string>;
}

interface GenerateOptions {
  maxTokens?: number;
  temperature?: number;
  systemPrompt?: string;
  tools?: ToolDefinition[];    // Provider-specific schemas handled internally
  responseFormat?: 'text' | 'json';
}

interface GenerateResult {
  text: string;
  usage: { inputTokens: number; outputTokens: number };
  model: string;
  provider: string;
  costUsd: number;  // Always track cost
  latencyMs: number;
}

// Anthropic implementation
class AnthropicTextService implements TextGenerationService {
  private client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  async generate(prompt: string, options: GenerateOptions = {}): Promise<GenerateResult> {
    const start = Date.now();
    const response = await this.client.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: options.maxTokens ?? 1024,
      system: options.systemPrompt ? [
        { type: 'text', text: options.systemPrompt, cache_control: { type: 'ephemeral' } },
      ] : undefined,
      tools: options.tools?.map(t => this.mapTool(t)),
      messages: [{ role: 'user', content: prompt }],
    });

    return {
      text: response.content.filter(b => b.type === 'text').map(b => b.text).join(''),
      usage: { inputTokens: response.usage.input_tokens, outputTokens: response.usage.output_tokens },
      model: 'claude-sonnet-4-6',
      provider: 'anthropic',
      costUsd: this.calculateCost(response.usage),
      latencyMs: Date.now() - start,
    };
  }

  async *stream(prompt: string, options: GenerateOptions = {}): AsyncIterable<string> {
    const stream = await this.client.messages.stream({
      model: 'claude-sonnet-4-6',
      max_tokens: options.maxTokens ?? 1024,
      system: options.systemPrompt,
      messages: [{ role: 'user', content: prompt }],
    });

    for await (const chunk of stream) {
      if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
        yield chunk.delta.text;
      }
    }
  }

  private calculateCost(usage: { input_tokens: number; output_tokens: number }): number {
    return (usage.input_tokens * 3.0 + usage.output_tokens * 15.0) / 1_000_000;
  }
}
```

### Multi-Provider Strategy

```typescript
// Use different providers for different features based on strengths
// This is the RIGHT level of abstraction — per-feature, not universal

const featureProviders: Record<string, { provider: string; model: string; reason: string }> = {
  'customer-support': {
    provider: 'anthropic',
    model: 'claude-haiku-4-5-20251001',
    reason: 'Best instruction-following at lowest cost, tool use for order lookups',
  },
  'code-generation': {
    provider: 'anthropic',
    model: 'claude-sonnet-4-6',
    reason: 'Top coding benchmarks, best at following complex coding instructions',
  },
  'data-extraction': {
    provider: 'openai',
    model: 'gpt-4o-mini',
    reason: 'Structured Outputs with guaranteed JSON schema conformance',
  },
  'long-document-analysis': {
    provider: 'google',
    model: 'gemini-1.5-pro',
    reason: '1M token context window, native PDF/video understanding',
  },
  'real-time-chat': {
    provider: 'groq',
    model: 'llama-3.1-70b',
    reason: '<100ms TTFT, best for interactive conversations',
  },
  'enterprise-rag': {
    provider: 'aws-bedrock',
    model: 'claude-sonnet',
    reason: 'VPC isolation, IAM auth, Knowledge Bases managed RAG',
  },
};
```

### AWS Bedrock Integration

```typescript
// Bedrock: multi-model, VPC isolation, IAM auth — no API keys in code
import {
  BedrockRuntimeClient,
  InvokeModelWithResponseStreamCommand,
} from '@aws-sdk/client-bedrock-runtime';

const bedrock = new BedrockRuntimeClient({
  region: 'us-east-1',
  // IAM role auth — no API keys, auto-rotated credentials
  // Runs inside VPC — data never leaves your network
});

async function* streamWithBedrock(prompt: string): AsyncIterable<string> {
  const command = new InvokeModelWithResponseStreamCommand({
    modelId: 'anthropic.claude-3-5-sonnet-20241022-v2:0',
    contentType: 'application/json',
    body: JSON.stringify({
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  const response = await bedrock.send(command);

  if (response.body) {
    for await (const event of response.body) {
      if (event.chunk?.bytes) {
        const data = JSON.parse(new TextDecoder().decode(event.chunk.bytes));
        if (data.type === 'content_block_delta' && data.delta?.text) {
          yield data.delta.text;
        }
      }
    }
  }
}

// Use via VPC Endpoint — zero internet exposure
// aws ec2 create-vpc-endpoint --service-name com.amazonaws.us-east-1.bedrock-runtime ...
```

### Vercel AI SDK (Provider-Agnostic Streaming)

```typescript
// Vercel AI SDK: single API for multiple providers
// Simplest multi-provider abstraction for TypeScript/Next.js apps
import { generateText, streamText } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { openai } from '@ai-sdk/openai';
import { google } from '@ai-sdk/google';

// Same interface, different providers
const result = await generateText({
  model: anthropic('claude-sonnet-4-6'),  // or openai('gpt-4o') or google('gemini-1.5-pro')
  system: 'You are a helpful assistant.',
  prompt: 'Explain RAG architecture',
  tools: {
    searchDocs: {
      description: 'Search documentation',
      parameters: z.object({ query: z.string() }),
      execute: async ({ query }) => await searchDocs(query),
    },
  },
});

// Streaming (Next.js App Router)
export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: anthropic('claude-sonnet-4-6'),
    system: 'You are a helpful assistant.',
    messages,
  });

  return result.toDataStreamResponse(); // Automatic SSE streaming
}
```

### Cost Monitoring and Tracking

```typescript
// Track every AI request — provider, model, tokens, cost, feature, user
// Non-negotiable for any production AI system

interface AIUsageEvent {
  timestamp: Date;
  provider: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
  latencyMs: number;
  feature: string;     // Which product feature used this
  userId?: string;     // Per-user cost tracking
  cached: boolean;     // Was prompt caching used?
}

// Cost calculation per provider (approximate, check latest pricing)
const PRICING: Record<string, { input: number; output: number }> = {
  'claude-haiku-4-5-20251001':    { input: 0.25,  output: 1.25  },
  'claude-sonnet-4-6':            { input: 3.0,   output: 15.0  },
  'claude-opus-4-6':              { input: 15.0,  output: 75.0  },
  'gpt-4o':                       { input: 2.5,   output: 10.0  },
  'gpt-4o-mini':                  { input: 0.15,  output: 0.60  },
  'gemini-1.5-flash':             { input: 0.075, output: 0.30  },
  'gemini-1.5-pro':               { input: 1.25,  output: 5.0   },
};

function calculateCost(model: string, inputTokens: number, outputTokens: number): number {
  const pricing = PRICING[model];
  if (!pricing) return 0;
  return (inputTokens * pricing.input + outputTokens * pricing.output) / 1_000_000;
}

// Dashboard query: daily cost by feature
// SELECT feature, SUM(cost_usd) as total_cost, COUNT(*) as requests,
//        AVG(latency_ms) as avg_latency
// FROM ai_usage_events
// WHERE timestamp > NOW() - INTERVAL '24 hours'
// GROUP BY feature
// ORDER BY total_cost DESC;

// Alert: daily cost exceeds 2x average
// SELECT SUM(cost_usd) as today_cost
// FROM ai_usage_events
// WHERE timestamp > CURRENT_DATE
// HAVING SUM(cost_usd) > (SELECT AVG(daily_cost) * 2 FROM daily_cost_summary);
```

---

## Anti-Patterns ❌

### Building a Universal AI Provider Abstraction
**What it is**: Creating one interface that makes all AI providers interchangeable with identical APIs. "We'll build a provider-agnostic layer so we can switch providers with zero code changes."
**What breaks**: Provider-specific features that matter most can't be used: prompt caching (Anthropic only, 90% cost reduction), structured outputs with schema guarantee (OpenAI), 1M context window (Gemini), extended thinking (Anthropic), computer use (Anthropic). You end up with lowest common denominator = worst of all providers. Migration still requires prompt rewriting because each model responds differently to the same prompt.
**Fix**: Abstract at the service/feature level, not the provider level. Each feature picks the best provider. Provider-specific features are used freely within each service implementation. Migration is per-feature (2-4 weeks), not global.

### Hardcoding API Keys and Provider Calls Everywhere
**What it is**: Direct `new Anthropic({ apiKey: "sk-..." })` scattered across 20 files. No centralized AI service layer.
**What breaks**: Cannot switch providers without touching every file. Cannot add cost tracking, rate limiting, or caching without modifying every call site. API key rotation requires finding every hardcoded instance. No visibility into total AI spend.
**Fix**: Centralized AI service layer. Config-driven provider/model selection. Cost tracking middleware wraps every call. API keys in environment variables or secret manager, referenced once.

### Ignoring Rate Limits and Error Handling
**What it is**: No retry logic, no exponential backoff, no rate limit awareness. Just fire requests and hope for the best.
**What breaks**: 429 (rate limit) errors cascade into user-facing failures. Burst traffic gets throttled, responses drop. Provider outage takes down your entire feature. Cost spikes from retrying without backoff.
**Fix**: Exponential backoff with jitter (base 1s, max 60s). Request queue with concurrency limit. Provider fallback chain (primary → secondary → cached response). Circuit breaker pattern: if error rate >50% in 60s, stop trying and serve fallback.

### Not Tracking Costs Before Launch
**What it is**: "We'll optimize costs later. Let's just get it working first." Launches with Opus/GPT-4o for everything.
**What breaks**: $50/day dev cost becomes $5,000/day at 100x traffic. Finance team discovers the bill, panics. Feature gets killed instead of optimized. Nobody knows which feature costs what because there's no per-feature tracking.
**Fix**: Cost estimate formula BEFORE launch: `daily_requests × (avg_input_tokens × input_price + avg_output_tokens × output_price) / 1M`. Set budget alerts at 50%, 80%, 100%. Start with cheapest model (Haiku/Flash), upgrade only if quality metrics demand it. Track cost per feature from day one.

---

## Quick Reference

```
Cheapest per token: Gemini 1.5 Flash ($0.075/1M input)
Best code quality: Claude Sonnet 4 (top benchmarks)
Best long context: Gemini 1.5 Pro (1M-2M tokens)
Fastest TTFT: Groq LPU (<100ms)
Best enterprise compliance: Azure OpenAI (FedRAMP, IL5, HIPAA)
Best multi-model platform: AWS Bedrock (Claude + Llama + Mistral)
Best self-hosted: Meta Llama 3.1 + vLLM
EU data residency: Mistral AI (La Plateforme)
Best RAG pipeline: Cohere (Command R+ + Rerank v3)
Best TypeScript SDK: Vercel AI SDK (multi-provider, streaming)
Provider abstraction: per-feature service layer, NOT universal adapter
Cost tracking: log every request with model, tokens, feature, user
Cost formula: requests/day × (input_tokens × $/1M + output_tokens × $/1M)
Migration budget: 2-4 weeks per feature per provider switch
Rate limits: exponential backoff + jitter + circuit breaker + fallback chain
```
