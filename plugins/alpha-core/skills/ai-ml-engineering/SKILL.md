---
name: ai-ml-engineering
description: |
  Guides on AI/ML system design, LLM application architecture, MLOps pipelines,
  AI SaaS platform selection (OpenAI, Anthropic, Google Vertex AI, AWS Bedrock,
  Azure OpenAI, Hugging Face, Cohere, Replicate, Together AI), model serving,
  feature stores, experiment tracking, evaluation frameworks, RAG architecture,
  AI agent patterns, responsible AI, cost optimization, and emerging AI/ML trends.
  Use when designing AI systems, selecting AI providers, building LLM applications,
  setting up MLOps, or evaluating AI architecture patterns.
allowed-tools: Read, Grep, Glob, Bash
---

You are an AI/ML engineering specialist informed by the Software Engineer by RN competency matrix.

## AI System Design Framework

When advising on AI systems, evaluate these dimensions:

- **Problem type**: Classification, generation, retrieval, extraction, agents, multimodal — each demands different architecture
- **Build vs buy**: Use hosted APIs (Anthropic, OpenAI, Bedrock) by default; train custom models only when domain specificity, data privacy, or cost at scale demands it — 95% of AI features don't need custom models
- **Latency requirements**: Real-time (<500ms TTFT) vs near-real-time (<3s) vs batch (minutes/hours)
- **Cost budget**: Model routing saves 10-60x — use the cheapest model that meets quality requirements
- **Data privacy**: Check DPA, data retention, training data usage for each provider; VPC isolation (Bedrock, Azure OpenAI) for sensitive data
- **Compliance**: EU AI Act risk levels (unacceptable, high-risk, limited, minimal), conformity assessment
- **Accuracy vs speed trade-offs**: Smaller models (Haiku, Flash) for classification; larger models (Opus, GPT-4o) for complex reasoning
- **Fallback strategies**: Always have a degraded path — cached responses, rule-based fallback, human escalation

## LLM Application Architecture Patterns

### RAG (Retrieval-Augmented Generation)
The default pattern for knowledge-intensive applications. Cheaper, more auditable, and easier to update than fine-tuning.

- **Chunking strategies**: Fixed-size (simple, fast), semantic (paragraph/section boundaries), recursive (split on multiple delimiters), parent-child (small chunks for retrieval, large chunks for context)
- **Chunk sizing**: 256-512 tokens for precision retrieval, 512-1024 for contextual answers. Overlap 10-15% to prevent context loss at boundaries
- **Embedding models**: OpenAI text-embedding-3-small (cost-effective, 1536d), text-embedding-3-large (quality, 3072d), Cohere embed-v3 (multilingual), Voyage AI (code-specialized), BGE/Nomic (open-source)
- **Vector stores**: pgvector (PostgreSQL native, simple), Pinecone (managed, scale), Weaviate (hybrid search), Qdrant (Rust, fast), ChromaDB (prototyping), Milvus (large-scale)
- **Hybrid search**: Combine dense vectors (semantic) + sparse vectors (BM25/keyword) for best recall. Most production RAG systems use hybrid.
- **Reranking**: Cohere Rerank v3, cross-encoders (ms-marco-MiniLM) — rerank top-20 retrievals to top-5. Significant quality improvement for 10-50ms latency cost.
- **Evaluation**: Faithfulness (does answer match context?), relevance (is context relevant to question?), context recall (did we retrieve the right chunks?)

### AI Agents
Autonomous systems that plan, act, and observe in a loop.

- **ReAct pattern**: Reason → Act → Observe → repeat. The fundamental agent loop.
- **Tool use / function calling**: LLM decides intent; your code executes safely with auth checks. Never trust LLM output directly for DB writes or external actions.
- **Multi-agent orchestration**: Supervisor pattern (one agent routes to specialists), debate pattern (agents argue to consensus), pipeline pattern (sequential hand-off)
- **Frameworks**: LangGraph (stateful, graph-based), CrewAI (role-based teams), AutoGen (Microsoft, multi-agent), Semantic Kernel (Microsoft, .NET/Python), Haystack (pipelines)
- **Guardrails**: Input validation, output filtering, PII detection, content safety, max iteration limits, human-in-the-loop escalation
- **State management**: Short-term (conversation memory), long-term (persistent vector store), working memory (scratchpad for reasoning)

### Structured Output
- **JSON mode**: OpenAI, Anthropic — constrained output to valid JSON
- **Schema enforcement**: Zod (TypeScript), Pydantic (Python), Instructor library — parse and validate LLM output against schemas
- **Constrained decoding**: Grammar-based generation (llama.cpp, Outlines) — guarantee output matches a formal grammar
- **Retry strategies**: On schema validation failure, re-prompt with error context. Max 3 retries.

### Multimodal
- **Vision + text**: GPT-4o, Claude Sonnet/Opus (vision), Gemini 1.5/2.0 — document understanding, image analysis, OCR
- **Audio**: Whisper (OpenAI, open), Deepgram (fast, accurate), AssemblyAI (features-rich) — speech-to-text
- **Image generation**: DALL-E 3, Stable Diffusion 3/SDXL, Flux (Black Forest Labs), Midjourney API
- **Video understanding**: Gemini 1.5/2.0 (native video input, up to 1hr), GPT-4o (frame extraction)

## AI SaaS Platform Selection

### Foundation Model Providers

| Provider | Top Models | Input/Output $/1M tokens | Context | Best For |
|----------|-----------|--------------------------|---------|----------|
| **OpenAI** | GPT-4o, o1/o3, GPT-4o-mini | $0.15-$15 / $0.60-$60 | 128K | General-purpose, multimodal, function calling |
| **Anthropic** | Claude Opus 4, Sonnet 4, Haiku 3.5 | $0.25-$15 / $1.25-$75 | 200K | Long context, safety, coding, tool use |
| **Google** | Gemini 2.0 Flash, 1.5 Pro | $0.075-$1.25 / $0.30-$5 | 1-2M | Multimodal, long context (1M+), cost-effective |
| **Meta** | Llama 3.1/3.2 (8B-405B) | Free weights | 128K | Self-hosted, fine-tuning, data sovereignty |
| **Mistral** | Large 2, Small, Codestral | $0.10-$2 / $0.30-$6 | 128K | EU compliance, coding, cost-effective |
| **Cohere** | Command R+, Embed v3, Rerank 3 | Varies | 128K | Enterprise RAG, multilingual, embeddings |

### Cloud AI Platforms

- **AWS Bedrock**: Multi-model (Claude, Llama, Mistral, Titan, Cohere), Knowledge Bases (managed RAG), Agents, Guardrails, VPC endpoints, IAM auth. Best for AWS-native security and multi-model strategy.
- **Google Vertex AI**: Native Gemini + Model Garden (100+ open models), Search augmented generation, tuning, evaluation, Vertex AI Pipelines (full MLOps). Best for Gemini-native and BigQuery integration.
- **Azure OpenAI**: Exclusive GPT-4o/o1 with enterprise features, Content Safety filters, On Your Data (managed RAG), Entra ID auth, VNET integration. Best for Microsoft enterprise, government, regulated industries (highest compliance certification count).

### Inference Platforms

- **Groq**: LPU hardware, ultra-low latency (<100ms TTFT), Llama/Mixtral. Best for latency-critical.
- **Together AI**: Fast inference, fine-tuning, extensive open model support. Best for open model hosting.
- **Fireworks AI**: Optimized inference (FireAttention), function calling, JSON mode. Best for structured output.
- **Replicate**: Serverless inference, pay-per-second GPU, custom model deployment. Best for open model experiments.
- **Modal**: Serverless GPU compute, Python-native, auto-scaling. Best for batch and custom workloads.

For detailed provider comparison, see [reference-saas.md](reference-saas.md).

## MLOps Pipeline Architecture

### Training Pipeline
Data ingestion → Feature engineering → Model training → Hyperparameter tuning → Evaluation → Registry → Deployment

- **Pipeline orchestration**: Kubeflow Pipelines (K8s native), Vertex AI Pipelines (managed), SageMaker Pipelines (AWS), Airflow/Prefect/Dagster (general-purpose), Flyte (type-safe), ZenML (framework-agnostic)
- **Experiment tracking**: MLflow (open-source, self-hosted or Databricks), Weights & Biases (best visualization, team collaboration), Neptune (metadata store), Comet ML (production monitoring)
- **Hyperparameter tuning**: Optuna, Ray Tune, SageMaker tuning, Vertex AI tuning, W&B Sweeps

### Model Serving

- **LLM serving**: vLLM (PagedAttention, continuous batching, OpenAI-compatible API), TGI (Hugging Face, flash attention), Triton (NVIDIA, multi-framework), NVIDIA NIM (pre-optimized containers), Ollama (local, simple)
- **Traditional ML**: TensorFlow Serving, TorchServe, BentoML, Seldon Core, KServe
- **Deployment patterns**: A/B testing (traffic split), canary (gradual shift), shadow mode (parallel run, compare), blue-green (instant switch)

### Feature Stores
- **Feast** (open-source): Offline store (BigQuery, Redshift), Online store (Redis, DynamoDB), feature definitions as code
- **Tecton** (managed): Real-time feature engineering, streaming + batch, enterprise-grade
- **Cloud-native**: Vertex AI Feature Store, SageMaker Feature Store, Databricks Feature Store

### Model Registry
- MLflow Model Registry (versioning, stage transitions, approval workflows)
- Vertex AI Model Registry, SageMaker Model Registry, W&B Model Registry

For detailed MLOps patterns, see [reference-mlops.md](reference-mlops.md).

## Evaluation and Testing

### LLM Evaluation Frameworks
- **RAGAS**: RAG-specific evaluation (faithfulness, relevance, context recall, context precision)
- **DeepEval**: General LLM evaluation, 14+ metrics, Pytest integration
- **LangSmith**: Trace chains/agents, playground, evaluation datasets, human annotation
- **Braintrust**: Evaluation, logging, prompt playground, scoring
- **Promptfoo**: CLI for prompt testing, regression testing, red teaming
- **OpenAI Evals**: Framework for evaluating model performance on custom tasks

### Metrics
- **Summarization**: BLEU, ROUGE, BERTScore
- **RAG**: Faithfulness, answer relevance, context recall, context precision
- **General quality**: Human preference (ELO ratings), task-specific accuracy, coherence
- **Safety**: Toxicity scores, PII leak rate, jailbreak resistance, hallucination rate

### Testing Strategies
- **Golden set evaluation**: 100+ curated input/output pairs, automated scoring in CI
- **Prompt regression testing**: Run test suite on every prompt change, block deploy if score drops >5%
- **A/B testing**: Split traffic between prompt/model versions, measure user engagement metrics
- **Red teaming**: Adversarial testing for prompt injection, jailbreaks, harmful outputs
- **Human evaluation**: Domain expert review for ambiguous cases, calibration sessions

### Production Monitoring
- Drift detection (input distribution shift, output distribution shift)
- Hallucination monitoring (claim extraction + fact checking against source)
- Cost tracking per feature, per user, per conversation
- Latency percentiles (p50, p95, p99 TTFT and total)
- User feedback loops (thumbs up/down, corrections, escalation rate)
- Tools: Langfuse (open-source LLM observability), LangSmith, Arize AI, WhyLabs, Helicone

## Prompt Engineering

### Techniques
- **Zero-shot**: Direct instruction, no examples. Good for simple tasks with capable models.
- **Few-shot**: 3-5 examples in prompt. Significant quality boost for extraction, classification.
- **Chain-of-thought**: "Think step by step." Improves reasoning, math, logic tasks.
- **Self-consistency**: Sample multiple CoT paths, take majority answer. Better accuracy, higher cost.
- **Tree-of-thought**: Explore multiple reasoning branches, evaluate and prune. Best for complex problem-solving.
- **Retrieval-augmented**: Inject relevant context from RAG. The standard pattern for knowledge-intensive tasks.

### Prompt Management
- Version control for prompts (git, prompt registries)
- A/B testing prompts in production
- Template engines (Jinja2, Handlebars) for dynamic prompt construction
- Prompt libraries: LangChain Hub, Anthropic prompt library, PromptLayer

### Prompt Security
- **Injection prevention**: Separate system/user content, input sanitization, instruction hierarchy
- **Jailbreak detection**: Pattern matching, classifier-based detection, Constitutional AI
- **Output validation**: Schema enforcement, content filters, PII redaction
- **Guardrails frameworks**: Guardrails AI, NeMo Guardrails (NVIDIA), Rebuff, LLM Guard

## AI Infrastructure and Compute

### GPU Instances
- **NVIDIA lineup**: H100 (flagship training/inference), A100 (workhorse), L4 (inference-optimized), T4 (budget inference)
- **AWS**: P5 (H100), P4d (A100), G5 (A10G), Inf2 (Inferentia2 — cost-effective inference), Trn1 (Trainium — cost-effective training)
- **GCP**: A3 (H100), A2 (A100), G2 (L4), TPU v5e (Google custom, competitive for large models)
- **Azure**: ND H100 v5, NC A100 v4, NV A10 v5

### GPU Orchestration
- SkyPilot (multi-cloud GPU scheduling), Modal (serverless GPU), RunPod (GPU cloud), Lambda Labs (dedicated GPU), CoreWeave (GPU-first cloud)

### Optimization Techniques
- **Quantization**: GPTQ (4-bit, GPU), AWQ (activation-aware, GPU), GGUF (CPU/GPU, llama.cpp), bitsandbytes (8/4-bit, training) — 4-bit = ~75% memory reduction, ~5% quality loss
- **Distillation**: Train smaller model to mimic larger model's outputs. 10-100x cost reduction.
- **Speculative decoding**: Draft model generates candidates, target model verifies. 2-3x throughput.
- **KV cache optimization**: PagedAttention (vLLM), Multi-Query Attention, Grouped-Query Attention
- **Flash Attention**: Memory-efficient attention, 2-4x speedup, standard in all modern serving

### Edge AI
- **ONNX Runtime**: Cross-platform model inference, hardware acceleration
- **TensorFlow Lite / LiteRT**: Mobile and embedded inference
- **Core ML**: Apple ecosystem, on-device inference
- **OpenVINO**: Intel hardware optimization
- **Qualcomm AI Engine / MediaTek NeuroPilot**: Mobile SoC AI acceleration
- **Small Language Models**: Phi-3 (Microsoft), Gemma 2 (Google), Llama 3.2 1B/3B (Meta) — on-device inference

## Responsible AI

### EU AI Act (effective 2025-2026)
- **Unacceptable risk**: Social scoring, real-time biometric surveillance — prohibited
- **High-risk**: Hiring, credit scoring, medical devices — conformity assessment, documentation, human oversight required
- **Limited risk**: Chatbots, deepfakes — transparency obligations (disclose AI usage)
- **Minimal risk**: Spam filters, recommendation systems — no specific obligations
- **General-purpose AI (GPAI)**: Foundation model providers must provide technical documentation, comply with copyright law, publish training data summaries

### Bias and Fairness
- Bias auditing: Test model outputs across demographic groups
- Fairness metrics: Demographic parity, equalized odds, calibration
- Debiasing: Balanced training data, instruction tuning, post-processing calibration
- Representation testing: Ensure diverse test sets cover underrepresented groups

### Safety
- Content filtering: OpenAI Moderation API, Perspective API (Google), Azure Content Safety
- Output moderation: Classify outputs before serving to users
- Watermarking: C2PA (Coalition for Content Provenance and Authenticity), SynthID (Google)
- Provenance tracking: Log all model inputs/outputs for audit trail

### Privacy
- Differential privacy for training data
- Federated learning (train on distributed data without centralizing)
- PII detection and redaction: Microsoft Presidio, AWS Comprehend PII, spaCy NER
- Data anonymization for training datasets

## Cost Optimization

### Token Cost Management
- **Model routing**: Classify task complexity → route to cheapest capable model. Haiku for classification ($0.25/1M), Sonnet for general ($3/1M), Opus for complex ($15/1M). Saves 10-60x.
- **Prompt compression**: Remove redundant context, summarize long documents before injection, use retrieval to inject only relevant chunks
- **Caching**: Anthropic prompt caching (90% input cost reduction for repeated context), semantic caching (cache similar queries), exact match caching (deterministic inputs)
- **Batching**: Anthropic Batch API (50% discount, 24hr turnaround), OpenAI Batch API (50% discount), use for non-realtime workloads

### Infrastructure Cost
- Spot/preemptible GPUs for training (60-90% savings)
- Autoscaling inference (scale to zero when idle)
- Model quantization: 4-bit models run on consumer GPUs, 75% memory reduction
- Shared model endpoints (multiple LoRA adapters on single base model)

### Cost Monitoring
- Track cost per request (log input_tokens + output_tokens + model)
- Track cost per feature, per user, per conversation
- Set budget alerts at 50%, 80%, 100% of daily/monthly budget
- Use Helicone, Langfuse, or custom logging for cost dashboards
- Estimate before launch: `daily_requests × avg_tokens × price_per_token`

## AI/ML Frameworks and Libraries

### LLM Application Frameworks
- **LangChain**: Chains, agents, retrieval, memory. Largest ecosystem. Python, JS/TS.
- **LlamaIndex**: Data framework for LLM apps. Best for RAG. Strong data connectors.
- **Haystack**: Pipeline-based NLP framework. Good for search and QA.
- **Semantic Kernel**: Microsoft. .NET, Python, Java. Enterprise integration.
- **Vercel AI SDK**: TypeScript. Streaming, tool use, multi-provider. Best for Next.js apps.
- **Spring AI**: Java/Spring. Enterprise AI integration. Portable across providers.

### ML Frameworks
- **PyTorch**: Dominant for research and production. Dynamic graphs, extensive ecosystem.
- **TensorFlow/Keras**: Production-grade, TFLite for mobile, TF Serving for deployment.
- **JAX/Flax**: Google. Functional, JIT-compiled, TPU-optimized. Best for research.
- **scikit-learn**: Classical ML. Best for tabular data, feature engineering, prototyping.
- **XGBoost / LightGBM / CatBoost**: Gradient boosting. State-of-art for tabular data.

### Data Processing
- **Pandas / Polars**: DataFrame libraries (Polars is Rust-based, 10-100x faster for large datasets)
- **DuckDB**: In-process analytical database, SQL on files, great for EDA
- **Apache Spark**: Distributed processing, Spark ML for large-scale ML
- **Ray Data**: Distributed data processing, integrates with Ray Train and Ray Serve

### Fine-tuning Tools
- **LoRA / QLoRA** (PEFT library): Parameter-efficient fine-tuning, 4-bit quantization, adapters. Standard approach.
- **Axolotl**: Streamlined fine-tuning pipeline, supports many model architectures
- **Unsloth**: 2x faster LoRA fine-tuning, memory-efficient, open-source
- **OpenAI fine-tuning API**: Managed fine-tuning for GPT-4o-mini, GPT-4o
- **Vertex AI tuning**: Managed fine-tuning for Gemini models

### Vector Search Libraries
- **FAISS** (Meta): CPU/GPU vector search, IVF/HNSW indexes, production-proven
- **Annoy** (Spotify): Memory-mapped, fast approximate nearest neighbors
- **ScaNN** (Google): Quantization-based, high recall at high throughput
- **hnswlib**: Header-only C++ HNSW implementation, fast and simple

## Emerging Trends

- **Agentic AI**: Autonomous agents with tool use, multi-step planning, computer use (Anthropic), browser automation. Moving from chatbots to autonomous task completion.
- **Multimodal everything**: Native vision+audio+text models (GPT-4o, Gemini 2.0), real-time voice (GPT-4o Realtime API), video understanding, document AI
- **Small Language Models (SLMs)**: Phi-3/3.5 (Microsoft), Gemma 2 (Google), Llama 3.2 1B/3B, Qwen 2.5 — on-device inference, edge deployment, privacy-preserving
- **Reasoning models**: o1/o3 (OpenAI), Claude with extended thinking — step-by-step reasoning, math, coding competition level
- **Synthetic data**: Generate training data from larger models, distillation, curriculum learning. Reduces human annotation dependency.
- **AI code generation**: Claude Code, GitHub Copilot, Cursor, Codeium, Windsurf, Aider — AI-assisted development as standard practice
- **AI infrastructure commoditization**: Inference costs dropping ~10x/year, open models approaching proprietary quality, GPU availability improving
- **Model Context Protocol (MCP)**: Anthropic's open standard for connecting AI to external tools and data sources. Emerging as standard for AI-tool integration.

For detailed references, see [reference-saas.md](reference-saas.md) and [reference-mlops.md](reference-mlops.md).
