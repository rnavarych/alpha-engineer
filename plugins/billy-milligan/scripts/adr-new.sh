#!/usr/bin/env bash
# ADR New — Create a new Architecture Decision Record
# Creates docs/adr/NNN-<slug>.md with the next sequential number.
# ADRs are formal, professional, and NEVER contain Billy voice.
# Works whether Billy is ON or OFF.
#
# Usage: adr-new.sh "<title>" [status]
# Output: path to the new ADR file

set -euo pipefail

ADR_DIR="docs/adr"
TITLE="${1:-}"
STATUS="${2:-PROPOSED}"

if [[ -z "$TITLE" ]]; then
  echo "Error: title required" >&2
  echo "Usage: adr-new.sh \"<title>\" [PROPOSED|ACCEPTED]" >&2
  exit 1
fi

# Ensure docs/adr/ exists
mkdir -p "$ADR_DIR"

# Find next sequential ADR number
NEXT_NUM=1
if ls "$ADR_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | head -1 > /dev/null; then
  LAST_NUM=$(ls "$ADR_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | \
    sed 's|.*/\([0-9]*\)-.*|\1|' | \
    sort -n | \
    tail -1)
  NEXT_NUM=$((10#$LAST_NUM + 1))
fi

# Format number as 3-digit padded
NUM_PADDED=$(printf "%03d" "$NEXT_NUM")

# Convert title to slug: lowercase, spaces → hyphens, strip special chars
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | tr -s '-')

# Create ADR filename
ADR_FILE="$ADR_DIR/${NUM_PADDED}-${SLUG}.md"
TODAY=$(date +%Y-%m-%d)

# Write ADR from template
cat > "$ADR_FILE" << EOF
# ADR-${NUM_PADDED}: ${TITLE}

## Status
${STATUS}

## Date
${TODAY}

## Context
[What is the issue? Why do we need to make this decision?]

## Options Considered

### Option A: [Name]
- **Pros:**
- **Cons:**

### Option B: [Name]
- **Pros:**
- **Cons:**

## Decision
[Which option was chosen.]

## Rationale
[Detailed reasoning behind the decision.]

## Consequences
[What becomes easier or harder? What new constraints does this introduce?]

## Related
[Links to other ADRs, issues, or documents.]
EOF

echo "$ADR_FILE"
