# MLOps Pipelines and Experiment Tracking

## When to load
Load when designing ML training pipelines, setting up experiment tracking (MLflow, W&B), working with feature stores, managing model registries, or implementing CI/CD for ML.

## ML Pipeline Architecture

```
Data Ingestion → Feature Engineering → Training → Evaluation → Registry → Serving → Monitoring
     ↑                                                                          |
     └──────────────────── Retraining Trigger ←─────────────────────────────────┘
```

### Pipeline Orchestration

| Tool | Type | Best For | Key Features |
|------|------|----------|-------------|
| **Kubeflow Pipelines** | K8s-native | Teams with K8s expertise | DAG-based, component reuse, KFP SDK, caching |
| **Vertex AI Pipelines** | Managed (GCP) | GCP shops | Kubeflow-compatible, managed infra, Vertex integration |
| **SageMaker Pipelines** | Managed (AWS) | AWS shops | Built-in steps (training, tuning, transform), model registry |
| **Prefect** | Modern orchestration | Python-native teams | Pythonic API, hybrid execution, better DX than Airflow |
| **Dagster** | Asset-based | Data-centric teams | Software-defined assets, type system, built-in observability |
| **Flyte** | Type-safe workflows | ML-heavy teams | Strong typing, versioning, multi-tenancy, caching |
| **ZenML** | Framework-agnostic | Multi-stack teams | Pluggable stacks, pipeline lineage, model control plane |

## Experiment Tracking

### MLflow

```python
mlflow.set_tracking_uri("http://mlflow-server:5000")
mlflow.set_experiment("my-rag-pipeline")
with mlflow.start_run():
    mlflow.log_params({"chunk_size": 512, "embedding_model": "text-embedding-3-small"})
    mlflow.log_metrics({"faithfulness": 0.87, "relevance": 0.92, "latency_p95_ms": 450})
    mlflow.log_artifact("evaluation_results.json")
    mlflow.pyfunc.log_model(artifact_path="rag-model", python_model=rag_pipeline,
        signature=mlflow.models.infer_signature(input_example, output_example))
```

- **Components**: Tracking (params/metrics/artifacts), Model Registry (version + stage transitions), Projects, Deployments
- **Deployment**: Self-hosted (Docker/K8s), Databricks (managed), Azure ML (integrated)

### Weights & Biases (W&B)
- **Experiments**: Interactive dashboards, custom charts, compare runs visually
- **Sweeps**: Hyperparameter tuning (Bayesian, grid, random) — distributed across machines
- **Artifacts**: Dataset and model versioning with lineage tracking
- **Weave**: LLM tracing and evaluation — trace function calls, log LLM inputs/outputs
- **Other tools**: Neptune (metadata store), Comet ML (experiment + production monitoring), Aim (open-source, self-hosted)

## Feature Stores

### Feast (Open-Source)

```python
driver_stats = FeatureView(name="driver_stats", entities=[driver], ttl=timedelta(days=1),
    schema=[Feature(name="avg_trip_distance", dtype=ValueType.FLOAT)],
    source=FileSource(path="data/driver_stats.parquet", timestamp_field="event_timestamp"))

# Point-in-time join prevents data leakage in training
training_df = store.get_historical_features(entity_df=entity_df,
    features=["driver_stats:avg_trip_distance"]).to_df()

# Online serving
features = store.get_online_features(features=["driver_stats:avg_rating"],
    entity_rows=[{"driver_id": 1001}]).to_dict()
```

- **Offline stores**: BigQuery, Redshift, Snowflake, Spark, PostgreSQL, Parquet
- **Online stores**: Redis, DynamoDB, PostgreSQL, SQLite
- **Tecton** (managed): Real-time feature engineering from streaming data (Kafka, Kinesis)
- **Cloud-native**: Vertex AI Feature Store (BigQuery-backed), SageMaker Feature Store, Databricks Feature Store

## CI/CD for ML

```yaml
# .github/workflows/model-eval.yml
on:
  pull_request:
    paths: ['prompts/**', 'config/models.yaml']
jobs:
  evaluate:
    steps:
      - uses: actions/checkout@v4
      - run: python eval/run_golden_set.py --config eval/golden_set.yaml
      - run: python eval/check_thresholds.py --min-faithfulness 0.85 --min-relevance 0.80 --max-latency-p95 500 --max-cost-per-request 0.05
```

**Deployment gates**: quality (faithfulness > 0.85) → latency (p95 < 500ms) → cost (<$0.05) → safety (no jailbreaks/PII) → human approval for high-risk

**Model versioning**: DVC (data + model files in git), MLflow Artifacts, W&B Artifacts (full lineage)

**Rollback**: model registry revert (<1min), prompt rollback via git, feature flag to disable AI entirely, canary stop
