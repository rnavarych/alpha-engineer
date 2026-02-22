# AI SaaS Platform Reference

## Foundation Model Providers

### OpenAI
- **Models**: GPT-4o (multimodal, 128K context), GPT-4o-mini (cost-efficient), o1/o3 (reasoning chains), GPT-4 Turbo (legacy)
- **Pricing (per 1M tokens)**: GPT-4o ~$2.50/$10 (input/output), GPT-4o-mini ~$0.15/$0.60, o1 ~$15/$60
- **API features**: Function calling (structured tool use), JSON mode, structured outputs (schema-constrained), vision (image input), DALL-E 3 (image generation), Whisper (speech-to-text), TTS, Batch API (50% discount, 24hr), Assistants API (threads, files, code interpreter), Realtime API (voice)
- **Fine-tuning**: GPT-4o-mini, GPT-4o — supervised fine-tuning, DPO support
- **Rate limits**: Tier-based (TPM/RPM), automatic scaling with usage history
- **SDKs**: Python, Node.js, REST. Ecosystem: ChatGPT plugins, GPTs, custom GPTs
- **Enterprise**: Azure OpenAI for dedicated capacity and compliance. API data NOT used for training.
- **Best for**: General-purpose, multimodal, function calling, real-time voice, code generation

### Anthropic (Claude)
- **Models**: Claude Opus 4 (complex reasoning, $15/$75), Claude Sonnet 4 (balanced, $3/$15), Claude 3.5 Haiku (fast/cheap, $0.25/$1.25)
- **Context window**: 200K tokens (all models). Extended thinking for complex reasoning.
- **API features**: Tool use (function calling), prompt caching (90% input cost reduction for cached tokens, 5-min TTL), extended thinking (chain-of-thought), computer use (GUI interaction), vision (image analysis), Batch API (50% discount), MCP (Model Context Protocol)
- **Fine-tuning**: Not publicly available (enterprise custom arrangements)
- **Rate limits**: Tier-based, automatic scaling
- **SDKs**: Python (`anthropic`), TypeScript (`@anthropic-ai/sdk`), REST
- **Enterprise**: SOC 2 Type II, HIPAA BAA available, Constitutional AI safety, AWS Bedrock and GCP Vertex AI integration
- **Best for**: Long context (200K), safety-critical applications, complex analysis, coding, tool use, agentic workflows

### Google (Gemini)
- **Models**: Gemini 2.0 Flash (fast multimodal), Gemini 1.5 Pro (1M-2M context), Gemini 1.5 Flash ($0.075/$0.30)
- **Context window**: Up to 2M tokens (Gemini 1.5 Pro) — largest available
- **API features**: Multimodal (text, image, video up to 1hr, audio, code), grounding with Google Search, function calling, code execution sandbox, caching
- **Access**: Google AI Studio (direct API, free tier), Vertex AI (enterprise, GCP integration)
- **Fine-tuning**: Supervised tuning, RLHF via Vertex AI, distillation from larger models
- **SDKs**: Python, Node.js, Go, REST, Genkit (AI framework)
- **Best for**: Multimodal (especially video/audio), extremely long context (1M-2M), Google Cloud integration, cost-effective (Flash)

### Meta (Llama)
- **Models**: Llama 3.1 (8B, 70B, 405B — 128K context), Llama 3.2 (1B, 3B text-only; 11B, 90B vision)
- **License**: Llama Community License — free for organizations with <700M monthly active users
- **Pricing**: Free weights. Inference cost depends on hosting platform.
- **Hosting**: Self-hosted (vLLM, TGI, Ollama), Together AI, Replicate, AWS Bedrock, Azure, Groq, Fireworks
- **Fine-tuning**: Full fine-tuning or LoRA/QLoRA with PEFT, Axolotl, Unsloth. Complete control.
- **Best for**: Self-hosted deployments, fine-tuning with custom data, data sovereignty, on-device (1B/3B), cost optimization at scale

### Mistral AI
- **Models**: Mistral Large 2 (123B, $2/$6), Mistral Small ($0.10/$0.30), Codestral (code-specialized), Pixtral (vision), Mixtral 8x22B (MoE, open)
- **Key differentiator**: European company — EU data residency, GDPR compliance by design
- **Access**: La Plateforme (direct), AWS Bedrock, Azure AI, GCP Vertex AI
- **Open models**: Mixtral 8x7B, Mistral 7B — Apache 2.0 license
- **Best for**: EU compliance requirements, coding tasks (Codestral), cost-effective alternatives to GPT-4o

### Cohere
- **Models**: Command R+ (RAG-optimized, 128K), Command R (efficient), Embed v3 (multilingual embeddings), Rerank 3 (reranking)
- **Focus**: Enterprise RAG, search, embeddings — not a general chatbot provider
- **Key differentiator**: Best-in-class reranking model, 100+ language embeddings, enterprise data connectors
- **Deployment**: Cohere API, AWS Bedrock, Azure, GCP, on-premises (Cohere Toolkit)
- **Best for**: Enterprise search and RAG, multilingual applications, embedding + reranking pipeline

## Cloud AI Platforms

### AWS Bedrock
- **Multi-model access**: Claude (Anthropic), Llama (Meta), Mistral, Amazon Titan, Stable Diffusion, Cohere, AI21 Labs
- **Managed features**: Knowledge Bases (managed RAG with S3/web sources), Agents (multi-step task automation), Guardrails (content filtering, PII redaction, topic denial), Model Evaluation (automated + human)
- **Fine-tuning**: Continued pre-training, fine-tuning for Titan, Llama, Cohere
- **Pricing**: Pay-per-token (on-demand), Provisioned Throughput (reserved capacity for predictable workloads)
- **Security**: VPC endpoints (no internet traversal), IAM integration, AWS PrivateLink, data not used for training, encryption at rest with KMS
- **Compliance**: SOC, HIPAA, PCI DSS, FedRAMP, ISO 27001, GDPR DPA
- **Best for**: Multi-model strategy, AWS-native applications, enterprise security requirements, government workloads

### Google Vertex AI
- **Model access**: Native Gemini (1.5 Pro, 1.5 Flash, 2.0 Flash), Model Garden (100+ open models: Llama, Mistral, Stable Diffusion, etc.)
- **Managed features**: Vertex AI Search (managed RAG with Google Search quality), Extensions (connect to Google services), Grounding (cite sources), Evaluation (AutoSxS, model comparison)
- **MLOps**: Vertex AI Pipelines (Kubeflow-based), Feature Store (BigQuery-backed), Model Registry, Experiments, TensorBoard
- **Fine-tuning**: Supervised tuning, RLHF, distillation for Gemini models
- **Security**: VPC Service Controls, Customer-Managed Encryption Keys (CMEK), Workload Identity, data residency controls
- **Best for**: Gemini-native applications, full MLOps lifecycle, BigQuery integration, data-intensive AI workloads

### Azure OpenAI Service
- **Exclusive access**: GPT-4o, o1, GPT-4 Turbo, DALL-E 3 with enterprise wrapping
- **Managed features**: On Your Data (managed RAG with Azure AI Search, Cosmos DB, Blob Storage), Content Safety (configurable filters), Prompt Shields (jailbreak detection)
- **Enterprise integration**: Entra ID (Azure AD) authentication, VNET integration, private endpoints, Azure Key Vault for API key management
- **Fine-tuning**: GPT-4o-mini, GPT-4o fine-tuning (managed)
- **Compliance**: Highest compliance certification count — FedRAMP High, IL5 (DoD), HIPAA, SOC 1/2/3, PCI DSS, ISO 27001/27018, GDPR
- **Best for**: Microsoft enterprise environments, government and regulated industries, Azure-native applications, Entra ID-secured AI

## Inference Platforms

### Groq
- **Hardware**: LPU (Language Processing Unit) — custom ASIC for LLM inference
- **Latency**: Ultra-fast — <100ms time to first token, 500-800 tokens/sec output
- **Models**: Llama 3.1 (8B, 70B), Mixtral 8x7B, Gemma 2 9B
- **Pricing**: Competitive with API providers, free tier available
- **Best for**: Latency-critical applications, real-time chat, interactive coding

### Together AI
- **Offering**: Fast inference + fine-tuning platform for open models
- **Models**: 100+ open models including Llama, Mistral, CodeLlama, Stable Diffusion
- **Features**: Together Embeddings, fine-tuning (LoRA, full), custom model hosting
- **Best for**: Open model inference and fine-tuning, team collaboration on models

### Fireworks AI
- **Offering**: Optimized inference with FireAttention engine
- **Features**: Function calling, JSON mode, grammar mode, speculative decoding
- **Models**: Llama, Mixtral, Gemma, custom model deployment
- **Best for**: Structured output, function calling with open models

### Replicate
- **Offering**: Serverless inference for any model, pay-per-second GPU billing
- **Features**: Cog packaging (Dockerize any model), community model library, fine-tuning, streaming
- **GPU types**: A40, A100, H100 — choose based on model requirements
- **Best for**: Prototyping, running community models, image/video generation

### Modal
- **Offering**: Serverless GPU compute with Python-native interface
- **Features**: Auto-scaling (including to zero), web endpoints, scheduled jobs, volumes for model weights
- **Best for**: Custom inference pipelines, batch processing, ML training jobs

## Embedding Providers Comparison

| Provider | Model | Dimensions | Max Tokens | $/1M Tokens | Multilingual | Notes |
|----------|-------|------------|------------|-------------|-------------|-------|
| OpenAI | text-embedding-3-small | 1536 | 8191 | $0.02 | Yes | Best cost/performance ratio |
| OpenAI | text-embedding-3-large | 3072 | 8191 | $0.13 | Yes | Highest quality, Matryoshka (dimension reduction) |
| Cohere | embed-v3 | 1024 | 512 | $0.10 | 100+ languages | Best multilingual, built-in search type (document/query) |
| Voyage AI | voyage-3 | 1024 | 32000 | $0.06 | Yes | Long context, code-specialized variant available |
| Google | text-embedding-004 | 768 | 2048 | $0.00625 | Yes | Cheapest, Vertex AI native |
| Mistral | mistral-embed | 1024 | 8192 | $0.10 | Yes | EU data residency |
| BGE | bge-large-en-v1.5 | 1024 | 512 | Free (self-host) | English | Best open-source, MTEB top |
| Nomic | nomic-embed-text-v1.5 | 768 | 8192 | Free (self-host) | Yes | Open-source, long context, Matryoshka |

## Platform Selection Decision Matrix

| Requirement | Recommended Platform | Rationale |
|-------------|---------------------|-----------|
| **Highest compliance (gov/regulated)** | Azure OpenAI | FedRAMP High, IL5, most certifications |
| **Multi-model flexibility** | AWS Bedrock | Claude + Llama + Mistral + Cohere in one API |
| **Best cost/performance** | Google Vertex AI (Flash) | Gemini Flash at $0.075/1M input |
| **Longest context window** | Google Vertex AI | Gemini 1.5 Pro supports 1-2M tokens |
| **Best coding quality** | Anthropic (Claude Sonnet) | Top coding benchmarks, tool use |
| **Lowest latency** | Groq | LPU hardware, <100ms TTFT |
| **Self-hosted / data sovereignty** | Meta Llama + vLLM | Free weights, full control |
| **EU data residency** | Mistral (La Plateforme) | European company, EU servers |
| **Enterprise RAG** | Cohere (Command R+ + Rerank) | Best retrieval pipeline quality |
| **Multimodal (video/audio)** | Google Gemini | Native video/audio understanding |
| **Maximum safety** | Anthropic Claude | Constitutional AI, RLHF, responsible scaling |
| **Microsoft ecosystem** | Azure OpenAI | Entra ID, Azure integration, Copilot stack |

## Provider Migration Checklist

When migrating between AI providers:

1. **Audit current usage**: Model, tokens/day, features used (function calling, vision, JSON mode)
2. **Map capabilities**: Not all features exist on all providers (e.g., prompt caching = Anthropic-specific)
3. **Adjust prompts**: Each model has different optimal prompt styles. Budget 1-2 days per feature for prompt tuning.
4. **Update schemas**: Function calling/tool use JSON schemas may have different formats
5. **Re-run evaluation**: Golden set test suite against new provider. Accept >5% quality delta or iterate prompts.
6. **Update cost estimates**: Token counts differ between tokenizers
7. **Verify compliance**: DPA, data retention, training data policies differ per provider
8. **Migration budget**: 2-4 weeks per provider switch per feature (including eval and prompt tuning)
