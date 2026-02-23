# Evaluation, Responsible AI, and Cost Optimization

## When to load
Load when setting up LLM evaluation frameworks, implementing production monitoring, working on responsible AI compliance (EU AI Act, bias, safety), optimizing AI costs, or choosing AI/ML frameworks and libraries.

## LLM Evaluation Frameworks

- **RAGAS**: RAG-specific evaluation (faithfulness, relevance, context recall, context precision)
- **DeepEval**: General LLM evaluation, 14+ metrics, Pytest integration
- **LangSmith**: Trace chains/agents, playground, evaluation datasets, human annotation
- **Braintrust**: Evaluation, logging, prompt playground, scoring
- **Promptfoo**: CLI for prompt testing, regression testing, red teaming
- **OpenAI Evals**: Framework for evaluating model performance on custom tasks

### Evaluation Metrics

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

## Responsible AI

### EU AI Act (effective 2025-2026)

- **Unacceptable risk**: Social scoring, real-time biometric surveillance — prohibited
- **High-risk**: Hiring, credit scoring, medical devices — conformity assessment, documentation, human oversight required
- **Limited risk**: Chatbots, deepfakes — transparency obligations (disclose AI usage)
- **Minimal risk**: Spam filters, recommendation systems — no specific obligations
- **GPAI (General-purpose AI)**: Foundation model providers must provide technical documentation, comply with copyright law, publish training data summaries

### Bias and Fairness

- Bias auditing: Test model outputs across demographic groups
- Fairness metrics: Demographic parity, equalized odds, calibration
- Debiasing: Balanced training data, instruction tuning, post-processing calibration

### Safety

- Content filtering: OpenAI Moderation API, Perspective API (Google), Azure Content Safety
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
- **Prompt compression**: Remove redundant context, summarize long documents, use retrieval to inject only relevant chunks
- **Caching**: Anthropic prompt caching (90% input cost reduction), semantic caching (cache similar queries), exact match caching
- **Batching**: Anthropic Batch API (50% discount, 24hr), OpenAI Batch API (50% discount) — for non-realtime workloads

### Infrastructure Cost

- Spot/preemptible GPUs for training (60-90% savings)
- Autoscaling inference (scale to zero when idle)
- Model quantization: 4-bit models run on consumer GPUs, 75% memory reduction
- Shared model endpoints (multiple LoRA adapters on single base model)
- Cost formula: `daily_requests × avg_tokens × price_per_token`
- Tools: Helicone, Langfuse for cost dashboards; set budget alerts at 50%, 80%, 100%

## AI/ML Frameworks and Libraries

### LLM Application Frameworks

- **LangChain**: Chains, agents, retrieval, memory. Largest ecosystem. Python, JS/TS.
- **LlamaIndex**: Data framework for LLM apps. Best for RAG. Strong data connectors.
- **Haystack**: Pipeline-based NLP. Good for search and QA.
- **Semantic Kernel**: Microsoft. .NET, Python, Java. Enterprise integration.
- **Vercel AI SDK**: TypeScript. Streaming, tool use, multi-provider. Best for Next.js.
- **Spring AI**: Java/Spring. Enterprise AI integration. Portable across providers.

### ML Frameworks

- **PyTorch**: Dominant for research and production. Dynamic graphs, extensive ecosystem.
- **TensorFlow/Keras**: Production-grade, TFLite for mobile, TF Serving for deployment.
- **JAX/Flax**: Google. Functional, JIT-compiled, TPU-optimized. Best for research.
- **scikit-learn**: Classical ML. Best for tabular data, feature engineering, prototyping.
- **XGBoost / LightGBM / CatBoost**: Gradient boosting. State-of-art for tabular data.

### GPU Orchestration and Optimization

- **GPU providers**: SkyPilot (multi-cloud), Modal (serverless), RunPod, Lambda Labs, CoreWeave
- **Quantization**: GPTQ (4-bit GPU), AWQ (activation-aware), GGUF (CPU/GPU), bitsandbytes — 4-bit = ~75% memory reduction, ~5% quality loss
- **Distillation**: Train smaller model to mimic larger model. 10-100x cost reduction.
- **Speculative decoding**: Draft model generates candidates, target model verifies. 2-3x throughput.
- **Flash Attention**: Memory-efficient attention, 2-4x speedup, standard in all modern serving

### Edge AI

- **ONNX Runtime**: Cross-platform model inference, hardware acceleration
- **TensorFlow Lite / LiteRT**: Mobile and embedded inference
- **Core ML**: Apple ecosystem, on-device inference
- **Small Language Models**: Phi-3 (Microsoft), Gemma 2 (Google), Llama 3.2 1B/3B (Meta) — on-device

## Emerging Trends

- **Agentic AI**: Autonomous agents with tool use, multi-step planning, computer use, browser automation
- **Multimodal everything**: Native vision+audio+text models, real-time voice (GPT-4o Realtime API)
- **Reasoning models**: o1/o3 (OpenAI), Claude with extended thinking — step-by-step, math, coding
- **Synthetic data**: Generate training data from larger models, distillation, curriculum learning
- **Model Context Protocol (MCP)**: Anthropic's open standard for connecting AI to external tools and data sources
- **AI infrastructure commoditization**: Inference costs dropping ~10x/year, open models approaching proprietary quality
