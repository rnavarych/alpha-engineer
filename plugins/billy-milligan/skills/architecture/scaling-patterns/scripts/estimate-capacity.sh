#!/usr/bin/env bash
# estimate-capacity.sh - Estimate infrastructure requirements based on traffic and data
# Usage: ./estimate-capacity.sh [rpm] [data_size_gb]
# Example: ./estimate-capacity.sh 5000 100
# Output: Infrastructure recommendations

set -euo pipefail

RPM="${1:-}"
DATA_SIZE_GB="${2:-}"

if [ -z "$RPM" ] || [ -z "$DATA_SIZE_GB" ]; then
  echo "Usage: ./estimate-capacity.sh <requests_per_minute> <data_size_gb>"
  echo "Example: ./estimate-capacity.sh 5000 100"
  echo ""
  echo "Parameters:"
  echo "  requests_per_minute: Expected peak RPM"
  echo "  data_size_gb: Current data size in GB"
  exit 1
fi

RPS=$((RPM / 60))

echo "## Capacity Estimation"
echo ""
echo "**Input**: ${RPM} RPM (${RPS} RPS), ${DATA_SIZE_GB}GB data"
echo ""

# --- Compute tier ---
echo "### Compute"
if [ "$RPM" -lt 1000 ]; then
  echo "- **Tier**: Small (single instance sufficient)"
  echo "- **Instance**: 2 vCPU, 4GB RAM (t3.medium / e2-medium)"
  echo "- **Instances**: 2 (for HA, not for load)"
  echo "- **Autoscaling**: not required at this scale"
elif [ "$RPM" -lt 10000 ]; then
  INSTANCES=$(( (RPM / 2000) + 1 ))
  [ "$INSTANCES" -lt 2 ] && INSTANCES=2
  echo "- **Tier**: Medium (multiple instances)"
  echo "- **Instance**: 4 vCPU, 8GB RAM (c6g.xlarge / c2-standard-4)"
  echo "- **Instances**: ${INSTANCES} minimum (2 per AZ)"
  echo "- **Autoscaling**: CPU target 70%, min=${INSTANCES}, max=$((INSTANCES * 3))"
  echo "- **Load balancer**: ALB/NLB with least-connections"
elif [ "$RPM" -lt 100000 ]; then
  INSTANCES=$(( (RPM / 3000) + 1 ))
  [ "$INSTANCES" -lt 4 ] && INSTANCES=4
  echo "- **Tier**: Large (horizontally scaled)"
  echo "- **Instance**: 8 vCPU, 16GB RAM (c6g.2xlarge / c2-standard-8)"
  echo "- **Instances**: ${INSTANCES} minimum (spread across 3 AZs)"
  echo "- **Autoscaling**: CPU 70%, custom metrics, min=${INSTANCES}, max=$((INSTANCES * 4))"
  echo "- **Load balancer**: ALB/NLB with health checks"
  echo "- **CDN**: Required (CloudFront/Cloudflare) for static assets"
else
  INSTANCES=$(( (RPM / 5000) + 1 ))
  echo "- **Tier**: Extra Large (distributed)"
  echo "- **Instance**: 16 vCPU, 32GB RAM (c6g.4xlarge / c2-standard-16)"
  echo "- **Instances**: ${INSTANCES}+ across multiple regions"
  echo "- **Autoscaling**: multi-metric (CPU, latency, queue depth)"
  echo "- **Architecture**: consider microservices decomposition"
  echo "- **CDN**: Required with edge computing"
fi

echo ""

# --- Database tier ---
echo "### Database"
if [ "$DATA_SIZE_GB" -lt 50 ]; then
  echo "- **Tier**: Small"
  echo "- **Engine**: PostgreSQL (single instance)"
  echo "- **Instance**: 4 vCPU, 32GB RAM (db.r6g.xlarge)"
  echo "- **Storage**: $((DATA_SIZE_GB * 3))GB (3x headroom) with auto-scaling"
  echo "- **Connection pool**: 9 connections (4 cores * 2 + 1)"
  echo "- **Read replicas**: 0 (add when read RPM > 5000)"
elif [ "$DATA_SIZE_GB" -lt 500 ]; then
  echo "- **Tier**: Medium"
  echo "- **Engine**: PostgreSQL with read replicas"
  echo "- **Primary**: 8 vCPU, 64GB RAM (db.r6g.2xlarge)"
  echo "- **Read replicas**: 1-2 (for read-heavy queries)"
  echo "- **Storage**: $((DATA_SIZE_GB * 2))GB with auto-scaling"
  echo "- **Connection pool**: PgBouncer (transaction mode, pool=20)"
  echo "- **Partitioning**: consider for tables >50GB"
else
  echo "- **Tier**: Large"
  echo "- **Engine**: PostgreSQL with sharding OR CockroachDB"
  echo "- **Primary**: 16 vCPU, 128GB RAM (db.r6g.4xlarge)"
  echo "- **Read replicas**: 2-4"
  echo "- **Storage**: $((DATA_SIZE_GB + (DATA_SIZE_GB / 2)))GB with auto-scaling"
  echo "- **Connection pool**: PgBouncer required (pool=40)"
  echo "- **Partitioning**: required for large tables"
  echo "- **Consider**: application-level sharding or CockroachDB"
fi

echo ""

# --- Cache tier ---
echo "### Cache (Redis)"
CACHE_MEMORY_GB=$(( (DATA_SIZE_GB / 10) + 1 ))
[ "$CACHE_MEMORY_GB" -lt 1 ] && CACHE_MEMORY_GB=1
[ "$CACHE_MEMORY_GB" -gt 64 ] && CACHE_MEMORY_GB=64

if [ "$RPM" -lt 5000 ]; then
  echo "- **Instance**: cache.r6g.large (2 vCPU, 13GB)"
  echo "- **Mode**: Single node with failover"
  echo "- **Max memory**: ${CACHE_MEMORY_GB}GB"
elif [ "$RPM" -lt 50000 ]; then
  echo "- **Instance**: cache.r6g.xlarge (4 vCPU, 26GB)"
  echo "- **Mode**: Cluster with 1 replica per shard"
  echo "- **Max memory**: ${CACHE_MEMORY_GB}GB per shard"
else
  SHARDS=$(( RPM / 20000 ))
  [ "$SHARDS" -lt 3 ] && SHARDS=3
  echo "- **Instance**: cache.r6g.xlarge per shard"
  echo "- **Mode**: Cluster with ${SHARDS} shards, 1 replica each"
  echo "- **Max memory**: ${CACHE_MEMORY_GB}GB per shard"
fi

echo ""

# --- Queue tier ---
echo "### Message Queue"
if [ "$RPM" -lt 10000 ]; then
  echo "- **Service**: SQS (managed, zero ops)"
  echo "- **Type**: Standard (or FIFO if ordering needed)"
  echo "- **Workers**: 2-4 instances"
elif [ "$RPM" -lt 100000 ]; then
  echo "- **Service**: SQS or RabbitMQ"
  echo "- **Workers**: $((RPM / 2000)) instances with autoscaling"
  echo "- **DLQ**: configured with maxReceiveCount=3"
else
  echo "- **Service**: Kafka (high throughput)"
  echo "- **Brokers**: 3 minimum"
  echo "- **Partitions**: $((RPM / 5000)) per topic"
  echo "- **Consumers**: match partition count"
fi

echo ""

# --- Summary ---
echo "### Cost estimate (rough monthly, AWS us-east-1)"
echo ""
echo "| Component | Configuration | Est. monthly cost |"
echo "|-----------|--------------|-------------------|"

if [ "$RPM" -lt 1000 ]; then
  echo "| Compute | 2x t3.medium | ~\$60 |"
  echo "| Database | db.r6g.large | ~\$200 |"
  echo "| Cache | cache.t3.medium | ~\$50 |"
  echo "| **Total** | | **~\$310/mo** |"
elif [ "$RPM" -lt 10000 ]; then
  echo "| Compute | ${INSTANCES}x c6g.xlarge | ~\$$(( INSTANCES * 120 )) |"
  echo "| Database | db.r6g.xlarge + replica | ~\$600 |"
  echo "| Cache | cache.r6g.large | ~\$200 |"
  echo "| Load Balancer | ALB | ~\$25 |"
  echo "| **Total** | | **~\$$(( (INSTANCES * 120) + 825 ))/mo** |"
else
  echo "| Compute | ${INSTANCES}x c6g.2xlarge+ | ~\$$(( INSTANCES * 250 )) |"
  echo "| Database | db.r6g.2xlarge+ replicas | ~\$1500 |"
  echo "| Cache | Redis cluster | ~\$500 |"
  echo "| Load Balancer | ALB | ~\$50 |"
  echo "| **Total** | | **~\$$(( (INSTANCES * 250) + 2050 ))/mo** |"
fi

echo ""
echo "**Note**: Estimates are rough. Actual costs vary by region, reserved instances, and data transfer."
echo "Use AWS Calculator or GCP Pricing Calculator for precise estimates."
