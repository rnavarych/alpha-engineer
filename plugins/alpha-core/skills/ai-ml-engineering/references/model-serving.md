# Model Serving, Fine-tuning, and Monitoring

## When to load
Load when deploying LLM serving engines (vLLM, TGI, Triton), implementing A/B testing or canary deployments for models, fine-tuning with LoRA/QLoRA, or setting up production monitoring and drift detection.

## LLM Serving Engines

### vLLM — Production Standard

```bash
python -m vllm.entrypoints.openai.api_server \
  --model meta-llama/Llama-3.3-70B-Instruct \
  --tensor-parallel-size 4 \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.90 \
  --enable-lora \
  --lora-modules customer-support=./loras/customer-support
```

- **PagedAttention**: ~24x throughput vs naive serving; **Continuous batching**: process new requests mid-batch
- **LoRA serving**: multiple adapters on single base model; **OpenAI-compatible API**: drop-in replacement

### Other Serving Options
- **TGI (Hugging Face)**: Rust-based, Flash Attention, GPTQ/AWQ quantization, streaming via SSE
- **Triton (NVIDIA)**: Multi-framework (PyTorch, TensorFlow, ONNX, TensorRT, vLLM), model ensemble
- **NVIDIA NIM**: Pre-built containers with TensorRT-LLM optimization, enterprise support
- **Ollama**: Local LLM running, GGUF format, automatic GPU/CPU detection
- **llama.cpp**: Minimal C/C++, GGUF quantization (Q4_K_M, Q5_K_M, Q8_0), CPU-friendly, ARM support

## Serving Deployment Patterns

```python
# A/B Testing — deterministic user assignment
def route_request(user_id: str, request: dict) -> str:
    bucket = hash(user_id) % 100
    model = "v2-candidate" if bucket < 10 else "v1-production"
    response = inference_service.predict(model=model, input=request)
    metrics.log(model=model, user_id=user_id, latency=response.latency)
    return response
```

- **Shadow mode**: Run new model in parallel, log both outputs, zero user impact
- **Canary**: 1% → 5% → 25% → 100%, auto-rollback if metrics degrade
- **Blue-green**: Instant switch, full rollback capability

## Fine-tuning: LoRA / QLoRA

```python
bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16, bnb_4bit_use_double_quant=True)
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.1-8B-Instruct",
    quantization_config=bnb_config, device_map="auto")
model = prepare_model_for_kbit_training(model)
lora_config = LoraConfig(r=32, lora_alpha=64,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.05, bias="none", task_type="CAUSAL_LM")
model = get_peft_model(model, lora_config)  # ~0.5% trainable parameters
```

**When to use**: Adapt style/format/domain; single GPU (24GB+ VRAM for 7B); hours not days.
**Data**: JSONL messages array, 100-1000 examples for style tuning, 1000-10000 for domain adaptation. Quality > quantity.

| Tool | Best For | Key Feature |
|------|----------|------------|
| **Axolotl** | Multi-architecture | YAML config, 20+ architectures, Flash Attention |
| **Unsloth** | Speed and memory | 2x faster, 60% less memory |
| **Hugging Face TRL** | RLHF/DPO training | SFTTrainer, DPOTrainer, PPOTrainer |
| **OpenAI API** | GPT-4o fine-tuning | Managed, upload JSONL |
| **Vertex AI** | Gemini fine-tuning | Supervised tuning, RLHF, distillation |

## Production Monitoring

**Drift detection**
- Data drift: PSI > 0.2 = significant; KL divergence, KS test
- Concept drift: monitor accuracy vs delayed ground truth; retrain when drops >5% from baseline
- Feature drift: mean, variance, null rate per feature

**LLM-specific metrics**: hallucination rate, safety violation rate, cost per request (model × tokens), TTFT p50/p95/p99, thumbs up/down ratio

| Tool | Type | Focus |
|------|------|-------|
| **Langfuse** | Open-source | LLM tracing, cost tracking, self-hosted |
| **LangSmith** | SaaS | Tracing, evaluation datasets, human annotation |
| **Arize AI** | SaaS | Drift detection, embedding visualization |
| **Helicone** | SaaS/OSS | Request logging, caching, proxy-based (no SDK) |
| **Evidently AI** | Open-source | Data drift reports, model performance dashboards |

**OpenTelemetry GenAI conventions**: `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`
