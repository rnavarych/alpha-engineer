#!/usr/bin/env bash
# analyze-data-model.sh - Reads schema files/migrations to suggest database fit
# Usage: ./analyze-data-model.sh [project-root]
# Output: Data model analysis and database recommendation

set -euo pipefail

PROJECT_ROOT="${1:-$PWD}"
INDICATORS=()
RELATIONAL_SCORE=0
DOCUMENT_SCORE=0
TIMESERIES_SCORE=0
GRAPH_SCORE=0
KEYVALUE_SCORE=0

echo "## Data Model Analysis"
echo ""
echo "**Scanning**: $PROJECT_ROOT"
echo ""

# Check for SQL migrations (Prisma, Drizzle, Knex, Flyway, golang-migrate)
MIGRATION_FILES=0
for pattern in "*.sql" "*.prisma" "schema.prisma" "drizzle/*.ts" "migrations/*.sql"; do
  count=$(find "$PROJECT_ROOT" -path "*/$pattern" -type f 2>/dev/null | head -50 | wc -l | tr -d ' ')
  MIGRATION_FILES=$((MIGRATION_FILES + count))
done

if [ "$MIGRATION_FILES" -gt 0 ]; then
  INDICATORS+=("Found $MIGRATION_FILES SQL/schema migration files")
  RELATIONAL_SCORE=$((RELATIONAL_SCORE + 3))
fi

# Check for Prisma schema
PRISMA_SCHEMA=$(find "$PROJECT_ROOT" -name "schema.prisma" -type f 2>/dev/null | head -1)
if [ -n "$PRISMA_SCHEMA" ]; then
  MODEL_COUNT=$(grep -c "^model " "$PRISMA_SCHEMA" 2>/dev/null || echo 0)
  RELATION_COUNT=$(grep -c "@relation" "$PRISMA_SCHEMA" 2>/dev/null || echo 0)
  JSON_FIELDS=$(grep -c "Json" "$PRISMA_SCHEMA" 2>/dev/null || echo 0)

  INDICATORS+=("Prisma schema: $MODEL_COUNT models, $RELATION_COUNT relations, $JSON_FIELDS JSON fields")
  RELATIONAL_SCORE=$((RELATIONAL_SCORE + 2))

  if [ "$RELATION_COUNT" -gt 5 ]; then
    RELATIONAL_SCORE=$((RELATIONAL_SCORE + 2))
    INDICATORS+=("High relation count ($RELATION_COUNT) - relational DB recommended")
  fi

  if [ "$JSON_FIELDS" -gt 3 ]; then
    DOCUMENT_SCORE=$((DOCUMENT_SCORE + 2))
    INDICATORS+=("Multiple JSON fields ($JSON_FIELDS) - consider document store for flexible data")
  fi
fi

# Check for MongoDB/Mongoose schemas
MONGOOSE_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | head -100 | xargs grep -l "mongoose\|Schema({" 2>/dev/null | wc -l | tr -d ' ')
if [ "$MONGOOSE_FILES" -gt 0 ]; then
  INDICATORS+=("Found $MONGOOSE_FILES Mongoose schema files")
  DOCUMENT_SCORE=$((DOCUMENT_SCORE + 3))
fi

# Check for DynamoDB patterns
DYNAMO_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.yaml" \) 2>/dev/null | head -100 | xargs grep -l "DynamoDB\|dynamodb\|AWS::DynamoDB" 2>/dev/null | wc -l | tr -d ' ')
if [ "$DYNAMO_FILES" -gt 0 ]; then
  INDICATORS+=("Found $DYNAMO_FILES DynamoDB-related files")
  KEYVALUE_SCORE=$((KEYVALUE_SCORE + 3))
fi

# Check for time-series patterns
TIMESERIES_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.sql" \) 2>/dev/null | head -100 | xargs grep -l "time_bucket\|hypertable\|timeseries\|InfluxDB\|TIMESTAMPTZ.*NOT NULL" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TIMESERIES_FILES" -gt 0 ]; then
  INDICATORS+=("Found $TIMESERIES_FILES time-series related files")
  TIMESERIES_SCORE=$((TIMESERIES_SCORE + 3))
fi

# Check for graph patterns
GRAPH_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.cypher" \) 2>/dev/null | head -100 | xargs grep -l "neo4j\|MATCH.*RETURN\|graph\|GraphQL.*relation" 2>/dev/null | wc -l | tr -d ' ')
if [ "$GRAPH_FILES" -gt 0 ]; then
  INDICATORS+=("Found $GRAPH_FILES graph-related files")
  GRAPH_SCORE=$((GRAPH_SCORE + 2))
fi

# Check for Redis usage
REDIS_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | head -100 | xargs grep -l "ioredis\|redis\|Redis" 2>/dev/null | wc -l | tr -d ' ')
if [ "$REDIS_FILES" -gt 0 ]; then
  INDICATORS+=("Found $REDIS_FILES Redis-related files (caching/sessions)")
  KEYVALUE_SCORE=$((KEYVALUE_SCORE + 1))
fi

# Check for Elasticsearch
ES_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.yaml" \) 2>/dev/null | head -100 | xargs grep -l "elasticsearch\|opensearch\|Elasticsearch" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ES_FILES" -gt 0 ]; then
  INDICATORS+=("Found $ES_FILES search engine files - likely secondary index")
fi

# Check for vector/embedding usage
VECTOR_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.sql" \) 2>/dev/null | head -100 | xargs grep -l "vector\|embedding\|pinecone\|pgvector\|similarity" 2>/dev/null | wc -l | tr -d ' ')
if [ "$VECTOR_FILES" -gt 0 ]; then
  INDICATORS+=("Found $VECTOR_FILES vector/embedding files - consider pgvector or Pinecone")
fi

# Output indicators
echo "**Indicators found**:"
if [ ${#INDICATORS[@]} -eq 0 ]; then
  echo "  - No database-specific patterns detected"
  echo "  - Recommendation: start with PostgreSQL (safe default)"
else
  for indicator in "${INDICATORS[@]}"; do
    echo "  - $indicator"
  done
fi

echo ""
echo "**Scores**:"
echo "  - Relational (Postgres/MySQL): $RELATIONAL_SCORE"
echo "  - Document (MongoDB): $DOCUMENT_SCORE"
echo "  - Time-series (TimescaleDB): $TIMESERIES_SCORE"
echo "  - Graph (Neo4j): $GRAPH_SCORE"
echo "  - Key-value (Redis/DynamoDB): $KEYVALUE_SCORE"

echo ""
echo "**Recommendation**:"
MAX_SCORE=$RELATIONAL_SCORE
RECOMMENDATION="PostgreSQL"

if [ "$DOCUMENT_SCORE" -gt "$MAX_SCORE" ]; then
  MAX_SCORE=$DOCUMENT_SCORE
  RECOMMENDATION="MongoDB"
fi
if [ "$TIMESERIES_SCORE" -gt "$MAX_SCORE" ]; then
  MAX_SCORE=$TIMESERIES_SCORE
  RECOMMENDATION="TimescaleDB (PostgreSQL extension)"
fi
if [ "$GRAPH_SCORE" -gt "$MAX_SCORE" ]; then
  MAX_SCORE=$GRAPH_SCORE
  RECOMMENDATION="Neo4j (or Postgres recursive CTEs for simpler graphs)"
fi
if [ "$KEYVALUE_SCORE" -gt "$MAX_SCORE" ]; then
  MAX_SCORE=$KEYVALUE_SCORE
  RECOMMENDATION="DynamoDB or Redis"
fi

echo "  Primary: **$RECOMMENDATION** (score: $MAX_SCORE)"
if [ "$REDIS_FILES" -gt 0 ] && [ "$RECOMMENDATION" != "DynamoDB or Redis" ]; then
  echo "  Secondary: Redis for caching/sessions"
fi
if [ "$ES_FILES" -gt 0 ]; then
  echo "  Secondary: Elasticsearch/OpenSearch for full-text search"
fi
if [ "$VECTOR_FILES" -gt 0 ]; then
  echo "  Secondary: pgvector or Pinecone for vector similarity search"
fi
