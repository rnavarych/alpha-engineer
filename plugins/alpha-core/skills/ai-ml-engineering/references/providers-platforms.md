# AI SaaS Providers and Platform Selection

## When to load
Load when selecting an AI provider or cloud AI platform, comparing foundation models by cost and capability, choosing an inference platform, comparing embedding providers, or planning a provider migration.

## Foundation Model Providers

| Provider | Top Models | Input/Output $/1M tokens | Context | Best For |
|----------|-----------|--------------------------|---------|----------|
| **OpenAI** | GPT-4.5, GPT-4o, o3/o4-mini, GPT-4o-mini | $0.15-$75 / $0.60-$300 | 128K | General-purpose, multimodal, function calling, real-time voice |
| **Anthropic** | Claude Opus 4.6, Sonnet 4.6, Haiku 4.5 | $0.80-$15 / $4-$75 | 200K | Long context, safety, coding, tool use, agentic workflows |
| **Google** | Gemini 2.5 Pro, 2.0 Flash, Flash Lite | $0.075-$1.25 / $0.30-$10 | 1-2M | Multimodal, extremely long context, cost-effective |
| **Meta** | Llama 3.3/3.2/3.1 (1B-405B) | Free weights | 128K | Self-hosted, fine-tuning, data sovereignty |
| **Mistral** | Large 2, Small 3, Codestral | $0.10-$2 / $0.30-$6 | 128K | EU compliance, coding, cost-effective |
| **Cohere** | Command R+, Embed v3, Rerank 3 | Varies | 128K | Enterprise RAG, multilingual, embeddings + reranking |

### Provider Detail: Anthropic

- **Model IDs**: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`
- **Prompt caching**: 90% input cost reduction for repeated context (5-min TTL); extended 1hr TTL available
- **Extended thinking**: Chain-of-thought for complex reasoning (Sonnet, Opus)
- **Computer use**: GUI interaction capability
- **Batch API**: 50% discount, 24hr turnaround — for non-realtime workloads
- **MCP (Model Context Protocol)**: Open standard for connecting AI to external tools and data sources
- Enterprise: SOC 2 Type II, HIPAA BAA, AWS Bedrock and GCP Vertex AI integration

### Provider Detail: Google Gemini

- **Context window**: Up to 2M tokens (Gemini 2.5 Pro / 2.0 series) — largest available
- **Multimodal**: Text, image, video up to 1hr, audio, code natively
- **Thinking**: Gemini 2.5 Pro has native chain-of-thought reasoning mode
- **Grounding**: With Google Search, function calling, code execution sandbox
- **Access**: Google AI Studio (direct API, free tier), Vertex AI (enterprise)

## Cloud AI Platforms

### AWS Bedrock

- **Multi-model access**: Claude, Llama, Mistral, Amazon Titan, Stable Diffusion, Cohere, AI21 Labs
- **Managed features**: Knowledge Bases (managed RAG), Agents (multi-step automation), Guardrails (content filtering, PII redaction, topic denial)
- **Security**: VPC endpoints (no internet traversal), IAM integration, data not used for training
- **Compliance**: SOC, HIPAA, PCI DSS, FedRAMP, ISO 27001, GDPR DPA
- **Best for**: Multi-model strategy, AWS-native applications, enterprise security, government workloads

### Google Vertex AI

- **Model access**: Native Gemini + Model Garden (100+ open models: Llama, Mistral, Stable Diffusion)
- **Managed features**: Vertex AI Search (managed RAG), Extensions (connect to Google services), AutoSxS evaluation
- **MLOps**: Vertex AI Pipelines (Kubeflow-based), Feature Store (BigQuery-backed), Model Registry, TensorBoard
- **Security**: VPC Service Controls, CMEK, data residency controls
- **Best for**: Gemini-native applications, full MLOps lifecycle, BigQuery integration

### Azure OpenAI Service

- **Exclusive access**: GPT-4.5, GPT-4o, o3, o4-mini, DALL-E 3 with enterprise wrapping
- **Managed features**: On Your Data (managed RAG), Content Safety, Prompt Shields (jailbreak detection)
- **Enterprise integration**: Entra ID auth, VNET integration, private endpoints, Key Vault
- **Compliance**: Highest count — FedRAMP High, IL5 (DoD), HIPAA, SOC 1/2/3, PCI DSS, ISO 27001/27018
- **Best for**: Microsoft enterprise, government and regulated industries, Azure-native applications

## Inference Platforms

- **Groq**: LPU hardware, <100ms TTFT, 500-800 tokens/sec. Best for latency-critical.
- **Together AI**: Fast inference + fine-tuning, 100+ open models. Best for open model hosting.
- **Fireworks AI**: FireAttention engine, structured output, function calling. Best for JSON mode.
- **Replicate**: Serverless inference, pay-per-second GPU, Cog packaging. Best for prototyping.
- **Modal**: Serverless GPU compute, Python-native, auto-scaling to zero. Best for custom pipelines.

## Embedding Providers

| Provider | Model | Dimensions | Max Tokens | $/1M Tokens | Notes |
|----------|-------|------------|------------|-------------|-------|
| OpenAI | text-embedding-3-small | 1536 | 8191 | $0.02 | Best cost/performance ratio |
| OpenAI | text-embedding-3-large | 3072 | 8191 | $0.13 | Highest quality, Matryoshka |
| Cohere | embed-v3 | 1024 | 512 | $0.10 | Best multilingual (100+ languages) |
| Voyage AI | voyage-3 | 1024 | 32000 | $0.06 | Long context, code-specialized variant |
| Google | text-embedding-004 | 768 | 2048 | $0.00625 | Cheapest, Vertex AI native |
| BGE | bge-large-en-v1.5 | 1024 | 512 | Free (self-host) | Best open-source, MTEB top |
| Nomic | nomic-embed-text-v1.5 | 768 | 8192 | Free (self-host) | Open-source, long context |

## Platform Selection Decision Matrix

| Requirement | Recommended | Rationale |
|-------------|-------------|-----------|
| **Highest compliance (gov/regulated)** | Azure OpenAI | FedRAMP High, IL5, most certifications |
| **Multi-model flexibility** | AWS Bedrock | Claude + Llama + Mistral + Cohere in one API |
| **Best cost/performance** | Google Vertex AI (Flash) | Gemini Flash at $0.075/1M input |
| **Longest context window** | Google Vertex AI | Gemini 2.5 Pro supports up to 2M tokens |
| **Best coding quality** | Anthropic Claude Sonnet | Top coding benchmarks, tool use |
| **Lowest latency** | Groq | LPU hardware, <100ms TTFT |
| **Self-hosted / data sovereignty** | Meta Llama + vLLM | Free weights, full control |
| **EU data residency** | Mistral (La Plateforme) | European company, EU servers |
| **Enterprise RAG** | Cohere (Command R+ + Rerank) | Best retrieval pipeline quality |
| **Maximum safety** | Anthropic Claude | Constitutional AI, RLHF |
| **Microsoft ecosystem** | Azure OpenAI | Entra ID, Azure integration |

## Provider Migration Checklist

1. **Audit current usage**: Model, tokens/day, features used (function calling, vision, JSON mode)
2. **Map capabilities**: Not all features exist on all providers (prompt caching = Anthropic-specific)
3. **Adjust prompts**: Each model has different optimal prompt styles. Budget 1-2 days per feature.
4. **Update schemas**: Function calling/tool use JSON schemas may differ
5. **Re-run evaluation**: Golden set test suite against new provider. Accept >5% quality delta or iterate.
6. **Verify compliance**: DPA, data retention, training data policies differ per provider
7. **Migration budget**: 2-4 weeks per provider switch per feature (including eval and prompt tuning)
