# MLOps Pipeline Reference

## ML Pipeline Architecture

End-to-end ML pipeline:
```
Data Ingestion → Feature Engineering → Training → Evaluation → Registry → Serving → Monitoring
     ↑                                                                          |
     └──────────────────── Retraining Trigger ←─────────────────────────────────┘
```

### Pipeline Orchestration

| Tool | Type | Best For | Key Features |
|------|------|----------|-------------|
| **Kubeflow Pipelines** | K8s-native | Teams with K8s expertise | DAG-based, component reuse, KFP SDK (Python), caching |
| **Vertex AI Pipelines** | Managed (GCP) | GCP shops | Kubeflow-compatible, managed infra, Vertex integration |
| **SageMaker Pipelines** | Managed (AWS) | AWS shops | Built-in steps (training, tuning, transform), model registry integration |
| **Airflow** | General orchestration | Existing Airflow users | Mature, extensible, huge operator library, but not ML-specific |
| **Prefect** | Modern orchestration | Python-native teams | Pythonic API, hybrid execution, better DX than Airflow |
| **Dagster** | Asset-based | Data-centric teams | Software-defined assets, type system, built-in observability |
| **Flyte** | Type-safe workflows | ML-heavy teams | Strong typing, versioning, multi-tenancy, caching |
| **ZenML** | Framework-agnostic | Multi-stack teams | Pluggable stacks (any infra), pipeline lineage, model control plane |

## Experiment Tracking

### MLflow
The open-source standard for experiment tracking and model management.

**Components**:
- **Tracking**: Log parameters, metrics, artifacts for every run. Auto-logging for PyTorch, TensorFlow, scikit-learn, XGBoost.
- **Model Registry**: Version models, transition stages (Staging → Production → Archived), approval workflows.
- **Projects**: Package ML code for reproducible runs (conda/docker environments).
- **Deployments**: Deploy to SageMaker, Azure ML, Databricks, local REST endpoint.

**Setup patterns**:
```python
# Self-hosted: PostgreSQL backend + S3 artifact store
# mlflow server --backend-store-uri postgresql://... --default-artifact-root s3://...

import mlflow

mlflow.set_tracking_uri("http://mlflow-server:5000")
mlflow.set_experiment("my-rag-pipeline")

with mlflow.start_run():
    mlflow.log_params({"chunk_size": 512, "embedding_model": "text-embedding-3-small"})
    mlflow.log_metrics({"faithfulness": 0.87, "relevance": 0.92, "latency_p95_ms": 450})
    mlflow.log_artifact("evaluation_results.json")

    # Log model with signature
    mlflow.pyfunc.log_model(
        artifact_path="rag-model",
        python_model=rag_pipeline,
        signature=mlflow.models.infer_signature(input_example, output_example),
    )
```

**Deployment options**: Self-hosted (Docker/K8s), Databricks (managed), Azure ML (integrated).

### Weights & Biases (W&B)
Best-in-class visualization and team collaboration.

- **Experiments**: Interactive dashboards, custom charts, compare runs visually
- **Sweeps**: Hyperparameter tuning (Bayesian, grid, random search) — distributed across machines
- **Artifacts**: Dataset and model versioning with lineage tracking
- **Tables**: Log and visualize predictions, data samples, confusion matrices interactively
- **Reports**: Shareable experiment reports with embedded charts and narratives
- **Launch**: Job scheduling and resource management for training runs
- **Weave** (new): LLM tracing and evaluation — trace function calls, log LLM inputs/outputs, build evaluation pipelines

**Integrations**: PyTorch, TensorFlow, Hugging Face Transformers, LangChain, LlamaIndex, Keras, scikit-learn, XGBoost, LightGBM.

### Other Tracking Tools

- **Neptune**: Metadata store for experiments, model registry, monitoring. Strong on comparison views and metadata queries.
- **Comet ML**: Experiment management + production model monitoring. Code change tracking, dataset versioning.
- **Aim**: Open-source experiment tracker. Fast UI for comparing 1000s of runs. Self-hosted only.

## Feature Stores

### Feast (Open-Source)
```python
# Define features as code
from feast import Entity, Feature, FeatureView, FileSource, ValueType

driver = Entity(name="driver_id", value_type=ValueType.INT64)

driver_stats = FeatureView(
    name="driver_stats",
    entities=[driver],
    ttl=timedelta(days=1),
    schema=[
        Feature(name="avg_trip_distance", dtype=ValueType.FLOAT),
        Feature(name="total_trips", dtype=ValueType.INT64),
        Feature(name="avg_rating", dtype=ValueType.FLOAT),
    ],
    source=FileSource(path="data/driver_stats.parquet", timestamp_field="event_timestamp"),
)

# Retrieve features for training (point-in-time join)
training_df = store.get_historical_features(
    entity_df=entity_df,  # entities + timestamps
    features=["driver_stats:avg_trip_distance", "driver_stats:total_trips"],
).to_df()

# Serve features online (real-time inference)
features = store.get_online_features(
    features=["driver_stats:avg_trip_distance", "driver_stats:avg_rating"],
    entity_rows=[{"driver_id": 1001}],
).to_dict()
```

**Offline stores**: BigQuery, Redshift, Snowflake, Spark, PostgreSQL, file-based (Parquet)
**Online stores**: Redis, DynamoDB, PostgreSQL, SQLite, Datastore
**Key concept**: Point-in-time joins prevent data leakage in training (use only features available at prediction time).

### Tecton (Managed)
- Built by Feast creators for enterprise scale
- Real-time feature engineering from streaming data (Kafka, Kinesis)
- Rift compute engine for batch + stream + real-time
- Feature monitoring and alerting
- Best for: high-throughput real-time ML (fraud detection, recommendations, pricing)

### Cloud-Native Feature Stores
- **Vertex AI Feature Store**: BigQuery-backed, feature monitoring, batch serving, point-in-time correctness
- **SageMaker Feature Store**: Online + offline stores, built-in, feature groups with metadata
- **Databricks Feature Store**: Unity Catalog integration, auto-log features with models

## Model Serving

### LLM Serving Engines

**vLLM** — Production standard for open model serving
```bash
# Start vLLM server with OpenAI-compatible API
python -m vllm.entrypoints.openai.api_server \
  --model meta-llama/Llama-3.1-70B-Instruct \
  --tensor-parallel-size 4 \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.90 \
  --enable-lora \
  --lora-modules customer-support=./loras/customer-support
```
- **PagedAttention**: Efficient KV cache management, ~24x throughput vs naive serving
- **Continuous batching**: Process new requests without waiting for batch completion
- **Tensor parallelism**: Distribute model across multiple GPUs
- **LoRA serving**: Load multiple LoRA adapters on single base model (multi-tenant)
- **OpenAI-compatible API**: Drop-in replacement for OpenAI client

**Text Generation Inference (TGI)** — Hugging Face
- Rust-based, Flash Attention, quantization (GPTQ, AWQ, EETQ, bitsandbytes)
- Streaming, token streaming via SSE
- Best for: Hugging Face model ecosystem users

**Triton Inference Server** — NVIDIA
- Multi-framework (PyTorch, TensorFlow, ONNX, TensorRT, vLLM backend)
- Dynamic batching, model ensemble (chain multiple models)
- Best for: Complex multi-model pipelines, mixed framework serving

**NVIDIA NIM** — Pre-optimized inference
- Pre-built containers with TensorRT-LLM optimization
- NVIDIA AI Enterprise support
- Best for: Enterprise deployment with NVIDIA support contract

**Ollama** — Local LLM running
```bash
ollama pull llama3.1:70b
ollama run llama3.1:70b "Explain RAG architecture"

# API access
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3.1:70b", "prompt": "..."}'
```
- GGUF format, automatic GPU/CPU detection
- Best for: Local development, prototyping, on-premises deployment

**llama.cpp** — Minimal C/C++ inference
- GGUF quantization (Q4_K_M, Q5_K_M, Q8_0 — different quality/speed trade-offs)
- CPU-friendly, ARM support (Apple Silicon optimized)
- Best for: Edge deployment, minimal dependencies, maximum portability

### Serving Patterns

**A/B Testing for Models**
```python
# Traffic splitting between model versions
import random

def route_request(user_id: str, request: dict) -> str:
    # Deterministic assignment based on user_id (consistent experience)
    bucket = hash(user_id) % 100

    if bucket < 10:  # 10% traffic to new model
        model = "v2-candidate"
    else:  # 90% traffic to production model
        model = "v1-production"

    response = inference_service.predict(model=model, input=request)

    # Log for analysis
    metrics.log(model=model, user_id=user_id, latency=response.latency, quality=response.quality_score)

    return response
```

**Shadow Mode** — Compare models without serving to users
- Run new model in parallel with production model
- Log both outputs, compare quality metrics
- Zero user impact during evaluation
- Graduate to A/B test when shadow metrics look good

**Canary Deployment** — Gradual traffic shift
- Deploy new model to small percentage (1% → 5% → 25% → 100%)
- Monitor error rates, latency, quality metrics at each stage
- Automatic rollback if metrics degrade beyond threshold

## Model Monitoring

### Drift Detection
- **Data drift**: Input distribution changes (new types of queries, different user demographics)
  - Statistical tests: PSI (Population Stability Index), KL divergence, Kolmogorov-Smirnov
  - Alert when PSI > 0.2 (significant drift)
- **Concept drift**: Relationship between input and output changes (model's knowledge becomes stale)
  - Monitor prediction accuracy over time against delayed ground truth
  - Trigger retraining when accuracy drops below baseline - 5%
- **Feature drift**: Individual feature distributions shift
  - Monitor mean, variance, min/max, null rate for each feature
  - Chi-squared test for categorical features, KS test for continuous

### LLM-Specific Monitoring
- **Hallucination rate**: Claim extraction + fact checking against source documents
- **Safety violations**: Content filter trigger rate, PII leak detection
- **Cost tracking**: Per-request cost (model × tokens), daily/weekly trends, cost per user/feature
- **Latency**: TTFT (time to first token), total generation time, p50/p95/p99
- **User satisfaction**: Thumbs up/down ratio, correction rate, escalation rate, regeneration rate
- **Token usage**: Average input/output tokens per request, context utilization rate

### Monitoring Tools

| Tool | Type | Focus | Key Features |
|------|------|-------|-------------|
| **Langfuse** | Open-source | LLM observability | Tracing, prompt management, scoring, cost tracking, self-hosted option |
| **LangSmith** | SaaS | LLM lifecycle | Tracing, evaluation datasets, playground, human annotation, LangChain native |
| **Arize AI** | SaaS | ML + LLM | Drift detection, performance monitoring, embedding visualization |
| **WhyLabs** | SaaS | ML monitoring | Data profiling, drift alerts, model performance, privacy-preserving |
| **Helicone** | SaaS/OSS | LLM proxy | Request logging, caching, rate limiting, cost tracking, proxy-based (no SDK) |
| **Evidently AI** | Open-source | ML monitoring | Data drift reports, model performance dashboards, test suites |
| **Fiddler** | SaaS | ML observability | Explainability, fairness monitoring, drift, performance |

## Fine-tuning Patterns

### LoRA / QLoRA (Parameter-Efficient Fine-Tuning)
```python
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

# QLoRA: 4-bit quantized base model + LoRA adapters
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,
)

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-3.1-8B-Instruct",
    quantization_config=bnb_config,
    device_map="auto",
)
model = prepare_model_for_kbit_training(model)

# LoRA config: rank 16-64, target attention layers
lora_config = LoraConfig(
    r=32,                        # Rank (16-64 typical)
    lora_alpha=64,               # Alpha (usually 2x rank)
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],  # Attention layers
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

model = get_peft_model(model, lora_config)
# Trainable parameters: ~0.5% of total (vs 100% for full fine-tuning)
```

**When to use LoRA/QLoRA**:
- Adapt model style, format, or domain vocabulary
- Budget: single GPU (24GB+ VRAM for 7B, 80GB for 70B with QLoRA)
- Training time: hours, not days
- Can serve multiple LoRA adapters on single base model (multi-tenant)

### Fine-tuning Tools Comparison

| Tool | Approach | Best For | Key Feature |
|------|----------|----------|------------|
| **Axolotl** | Configurable pipeline | Multi-architecture fine-tuning | YAML config, supports 20+ model architectures, Flash Attention |
| **Unsloth** | Optimized training | Speed and memory | 2x faster, 60% less memory, custom CUDA kernels, free tier |
| **Hugging Face TRL** | Library | RLHF/DPO training | SFTTrainer, DPOTrainer, PPOTrainer, reward modeling |
| **OpenAI API** | Managed | GPT-4o fine-tuning | Upload JSONL, managed training, automatic evaluation |
| **Vertex AI** | Managed | Gemini fine-tuning | Supervised tuning, RLHF, distillation |

### Data Preparation for Fine-tuning
```jsonl
{"messages": [{"role": "system", "content": "You are a customer support agent for Acme Corp."}, {"role": "user", "content": "How do I reset my password?"}, {"role": "assistant", "content": "To reset your password:\n1. Go to acme.com/reset\n2. Enter your email address\n3. Click the reset link sent to your email\n4. Choose a new password (min 12 characters)\n\nNeed more help? Contact support@acme.com"}]}
```

- **Format**: JSONL with messages array (chat format)
- **Volume**: 100-1000 examples for style/format tuning, 1000-10000 for domain adaptation
- **Quality**: Curate manually or use LLM-as-judge to filter. Quality > quantity.
- **Deduplication**: Remove near-duplicates to prevent memorization
- **Balance**: Ensure diverse examples across expected use cases

## CI/CD for ML

### Model Versioning
- **DVC (Data Version Control)**: Track data and model files alongside code in git. S3/GCS/Azure as remote storage.
- **Git LFS**: Large file storage in git. Simpler but less feature-rich than DVC.
- **MLflow Artifacts**: Store models and datasets as run artifacts. Versioned in model registry.
- **W&B Artifacts**: Dataset and model versioning with full lineage tracking.

### Automated Evaluation in CI
```yaml
# .github/workflows/model-eval.yml
name: Model Evaluation
on:
  pull_request:
    paths: ['prompts/**', 'config/models.yaml']

jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run golden set evaluation
        run: python eval/run_golden_set.py --config eval/golden_set.yaml
      - name: Check quality gate
        run: |
          python eval/check_thresholds.py \
            --min-faithfulness 0.85 \
            --min-relevance 0.80 \
            --max-latency-p95 500 \
            --max-cost-per-request 0.05
      - name: Post results to PR
        run: python eval/post_results.py --github-token ${{ secrets.GITHUB_TOKEN }}
```

### Deployment Gates
1. **Quality gate**: Automated eval score above threshold (e.g., faithfulness > 0.85)
2. **Latency gate**: p95 latency below SLA (e.g., <500ms TTFT)
3. **Cost gate**: Per-request cost within budget (e.g., <$0.05)
4. **Safety gate**: Content safety tests pass (no jailbreaks, no PII leaks)
5. **Bias gate**: Fairness metrics within acceptable range across demographic groups
6. **Human approval**: Domain expert sign-off for high-risk changes

### Rollback Strategies
- **Model rollback**: Revert to previous model version in registry (immediate, <1min)
- **Prompt rollback**: Revert prompt template via git (deploy on merge)
- **Feature flag**: Disable AI feature entirely, fallback to rule-based or cached responses
- **Canary stop**: Halt traffic shift and route 100% back to stable version

## LLM Observability and Tracing

### OpenTelemetry for GenAI
Emerging semantic conventions for LLM observability:
- `gen_ai.system`: Provider name (openai, anthropic, etc.)
- `gen_ai.request.model`: Model identifier
- `gen_ai.usage.input_tokens`: Input token count
- `gen_ai.usage.output_tokens`: Output token count
- `gen_ai.response.finish_reasons`: Why generation stopped

Integrations: OpenLLMetry (open-source), Traceloop, LangSmith, Langfuse all support OTel export.

### Tracing Architecture
```
User Request
  └── API Handler (span: http.request)
       └── RAG Pipeline (span: rag.pipeline)
            ├── Embedding (span: gen_ai.embed, tokens: 128)
            ├── Vector Search (span: db.query, results: 5)
            ├── Reranking (span: gen_ai.rerank, input: 5, output: 3)
            └── LLM Generation (span: gen_ai.chat, model: claude-sonnet, tokens: 1200)
                 └── Tool Use (span: tool.execute, name: get_order)
```

Each span captures: latency, token usage, cost, model, error status. Full trace enables root cause analysis for slow or incorrect responses.
