#!/usr/bin/env bash
# Billy Milligan — Skill Gaps Tracker
# Logs and manages skill gaps in ~/.claude/billy-memory/<project-hash>/skill-gaps.md
# Tracks topics that fell back to model knowledge (Level 4) or honest uncertainty (Level 5)
# in the universal fallback chain. Gaps inform which skills to create next.
#
# Usage:
#   skill-gaps.sh log-gap <priority> <agent> <query> <missing> <closest> <suggested>
#   skill-gaps.sh list
#   skill-gaps.sh clear
#   skill-gaps.sh promote <topic>
#   skill-gaps.sh dismiss <topic>
#   skill-gaps.sh summary
#   skill-gaps.sh create-check <topic>

set -euo pipefail

# Compute project-specific memory path (never inside the project repo)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if command -v md5 &>/dev/null; then
  PROJECT_HASH=$(echo -n "$PROJECT_DIR" | md5)
elif command -v md5sum &>/dev/null; then
  PROJECT_HASH=$(echo -n "$PROJECT_DIR" | md5sum | cut -d' ' -f1)
else
  PROJECT_HASH=$(echo -n "$PROJECT_DIR" | shasum -a 256 | cut -d' ' -f1 | head -c 32)
fi

MEMORY_DIR="$HOME/.claude/billy-memory/$PROJECT_HASH"
GAPS_FILE="$MEMORY_DIR/skill-gaps.md"

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Initialize gaps file if it doesn't exist
init_gaps_file() {
  if [[ ! -f "$GAPS_FILE" ]]; then
    cat > "$GAPS_FILE" << 'EOF'
# Skill Gaps — Knowledge Resolution Tracker

> Gaps logged by agents when falling back to Level 4-5 in the knowledge resolution chain.
> Use `/skills:create <topic>` to generate a new skill from a gap.

---
EOF
  fi
}

# Normalize topic for matching (lowercase, trim whitespace)
normalize_topic() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Check if a topic already exists in the gaps file (case-insensitive)
topic_exists() {
  local topic="$1"
  local normalized
  normalized=$(normalize_topic "$topic")
  if [[ -f "$GAPS_FILE" ]]; then
    grep -i "^### " "$GAPS_FILE" 2>/dev/null | while IFS= read -r line; do
      existing=$(echo "$line" | sed 's/^### //' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ "$existing" == "$normalized" ]]; then
        echo "FOUND"
        return
      fi
    done
  fi
}

# Get the exact topic heading as written in the file
get_exact_topic() {
  local topic="$1"
  local normalized
  normalized=$(normalize_topic "$topic")
  if [[ -f "$GAPS_FILE" ]]; then
    grep -i "^### " "$GAPS_FILE" 2>/dev/null | while IFS= read -r line; do
      existing=$(echo "$line" | sed 's/^### //' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ "$existing" == "$normalized" ]]; then
        echo "$line" | sed 's/^### //'
        return
      fi
    done
  fi
}

TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H:%M)
ACTION="${1:-list}"

case "$ACTION" in

  log-gap)
    PRIORITY="${2:-medium}"
    AGENT="${3:-unknown}"
    QUERY="${4:-}"
    MISSING="${5:-}"
    CLOSEST="${6:-none}"
    SUGGESTED="${7:-}"

    if [[ -z "$QUERY" ]]; then
      echo "Error: query text required" >&2
      echo "Usage: skill-gaps.sh log-gap <priority> <agent> <query> <missing> <closest> <suggested>" >&2
      exit 1
    fi

    init_gaps_file

    # Derive topic from the missing skill description
    TOPIC="${MISSING:-$QUERY}"

    # Check if topic already exists — increment instead of duplicate
    if [[ "$(topic_exists "$TOPIC")" == "FOUND" ]]; then
      # Increment frequency
      EXACT=$(get_exact_topic "$TOPIC")
      if [[ -n "$EXACT" ]]; then
        # Find the frequency line after this topic and increment
        if [[ "$(uname)" == "Darwin" ]]; then
          # macOS sed
          awk -v topic="### $EXACT" '
            $0 == topic { found=1 }
            found && /^\- \*\*Frequency:\*\*/ {
              match($0, /[0-9]+/)
              num = substr($0, RSTART, RLENGTH) + 1
              sub(/[0-9]+/, num)
              found=0
            }
            { print }
          ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"
        else
          awk -v topic="### $EXACT" '
            $0 == topic { found=1 }
            found && /^\- \*\*Frequency:\*\*/ {
              match($0, /[0-9]+/)
              num = substr($0, RSTART, RLENGTH) + 1
              sub(/[0-9]+/, num)
              found=0
            }
            { print }
          ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"
        fi

        # Check if frequency crossed auto-promote thresholds
        CURRENT_FREQ=$(awk -v topic="### $EXACT" '
          $0 == topic { found=1 }
          found && /^\- \*\*Frequency:\*\*/ { match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH); exit }
        ' "$GAPS_FILE")

        CURRENT_PRIORITY=$(awk -v topic="### $EXACT" '
          $0 == topic { found=1 }
          found && /^\- \*\*Priority:\*\*/ { gsub(/.*\*\* */, ""); print; exit }
        ' "$GAPS_FILE")

        # Auto-promote: 3+ hits → low→medium, 5+ hits → medium→high
        if [[ "$CURRENT_FREQ" -ge 5 && "$CURRENT_PRIORITY" == "medium" ]]; then
          awk -v topic="### $EXACT" '
            $0 == topic { found=1 }
            found && /^\- \*\*Priority:\*\*/ { sub(/medium/, "high"); found=0 }
            { print }
          ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"
        elif [[ "$CURRENT_FREQ" -ge 3 && "$CURRENT_PRIORITY" == "low" ]]; then
          awk -v topic="### $EXACT" '
            $0 == topic { found=1 }
            found && /^\- \*\*Priority:\*\*/ { sub(/low/, "medium"); found=0 }
            { print }
          ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"
        fi

        echo "Gap '$TOPIC' frequency incremented."
      fi
    else
      # Append new gap entry
      {
        echo ""
        echo "### $TOPIC"
        echo "- **Priority:** $PRIORITY"
        echo "- **First reported:** $TODAY $TIMESTAMP"
        echo "- **Agent:** $AGENT"
        echo "- **Query context:** $QUERY"
        echo "- **What was missing:** $MISSING"
        echo "- **Closest skill:** $CLOSEST"
        echo "- **Suggested skill:** $SUGGESTED"
        echo "- **Frequency:** 1"
        echo ""
      } >> "$GAPS_FILE"
      echo "Gap '$TOPIC' logged ($PRIORITY priority)."
    fi
    ;;

  list)
    init_gaps_file

    # Check if any gaps exist
    GAP_COUNT=$(grep -c "^### " "$GAPS_FILE" 2>/dev/null || echo "0")
    if [[ "$GAP_COUNT" -eq 0 ]]; then
      echo "No skill gaps recorded."
      exit 0
    fi

    # Output the full gaps file
    cat "$GAPS_FILE"
    echo ""
    echo "---"
    echo "Total gaps: $GAP_COUNT"

    # Count by priority (grep -c exits non-zero on no match, so handle that)
    HIGH_COUNT=$(grep -c '\*\*Priority:\*\* high' "$GAPS_FILE" 2>/dev/null || true)
    MEDIUM_COUNT=$(grep -c '\*\*Priority:\*\* medium' "$GAPS_FILE" 2>/dev/null || true)
    LOW_COUNT=$(grep -c '\*\*Priority:\*\* low' "$GAPS_FILE" 2>/dev/null || true)
    HIGH_COUNT=$((HIGH_COUNT + 0))
    MEDIUM_COUNT=$((MEDIUM_COUNT + 0))
    LOW_COUNT=$((LOW_COUNT + 0))
    echo "HIGH: $HIGH_COUNT | MEDIUM: $MEDIUM_COUNT | LOW: $LOW_COUNT"

    # Find highest frequency gap
    TOP_GAP=$(awk '/^### /{topic=substr($0,5)} /Frequency:/{match($0,/[0-9]+/); freq=substr($0,RSTART,RLENGTH); if(freq>max){max=freq; top=topic}} END{if(top)print top " (" max " hits)"}' "$GAPS_FILE")
    if [[ -n "$TOP_GAP" ]]; then
      echo "Top gap: $TOP_GAP"
    fi
    ;;

  clear)
    cat > "$GAPS_FILE" << 'EOF'
# Skill Gaps — Knowledge Resolution Tracker

> Gaps logged by agents when falling back to Level 4-5 in the knowledge resolution chain.
> Use `/skills:create <topic>` to generate a new skill from a gap.

---
EOF
    echo "All skill gaps cleared."
    ;;

  promote)
    TOPIC="${2:-}"
    if [[ -z "$TOPIC" ]]; then
      echo "Error: topic required" >&2
      echo "Usage: skill-gaps.sh promote <topic>" >&2
      exit 1
    fi

    init_gaps_file

    EXACT=$(get_exact_topic "$TOPIC")
    if [[ -z "$EXACT" ]]; then
      echo "Gap '$TOPIC' not found." >&2
      exit 1
    fi

    # Get current priority
    CURRENT_PRIORITY=$(awk -v topic="### $EXACT" '
      $0 == topic { found=1 }
      found && /^\- \*\*Priority:\*\*/ { gsub(/.*\*\* */, ""); print; exit }
    ' "$GAPS_FILE")

    case "$CURRENT_PRIORITY" in
      low)
        awk -v topic="### $EXACT" '
          $0 == topic { found=1 }
          found && /^\- \*\*Priority:\*\*/ { sub(/low/, "medium"); found=0 }
          { print }
        ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"
        echo "Gap '$TOPIC' promoted: low -> medium."
        ;;
      medium)
        awk -v topic="### $EXACT" '
          $0 == topic { found=1 }
          found && /^\- \*\*Priority:\*\*/ { sub(/medium/, "high"); found=0 }
          { print }
        ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"
        echo "Gap '$TOPIC' promoted: medium -> high."
        ;;
      high)
        echo "Gap '$TOPIC' is already high priority."
        ;;
      *)
        echo "Unknown priority '$CURRENT_PRIORITY' for gap '$TOPIC'." >&2
        exit 1
        ;;
    esac
    ;;

  dismiss)
    TOPIC="${2:-}"
    if [[ -z "$TOPIC" ]]; then
      echo "Error: topic required" >&2
      echo "Usage: skill-gaps.sh dismiss <topic>" >&2
      exit 1
    fi

    init_gaps_file

    EXACT=$(get_exact_topic "$TOPIC")
    if [[ -z "$EXACT" ]]; then
      echo "Gap '$TOPIC' not found." >&2
      exit 1
    fi

    # Remove the section from ### <topic> to the next ### or end of file
    awk -v topic="### $EXACT" '
      $0 == topic { skip=1; next }
      /^### / { skip=0 }
      !skip { print }
    ' "$GAPS_FILE" > "${GAPS_FILE}.tmp" && mv "${GAPS_FILE}.tmp" "$GAPS_FILE"

    echo "Gap '$TOPIC' dismissed."
    ;;

  summary)
    init_gaps_file

    GAP_COUNT=$(grep -c "^### " "$GAPS_FILE" 2>/dev/null || echo "0")
    if [[ "$GAP_COUNT" -eq 0 ]]; then
      echo "No skill gaps recorded."
      exit 0
    fi

    HIGH_COUNT=$(grep -c '\*\*Priority:\*\* high' "$GAPS_FILE" 2>/dev/null || echo "0")
    MEDIUM_COUNT=$(grep -c '\*\*Priority:\*\* medium' "$GAPS_FILE" 2>/dev/null || echo "0")

    TOTAL_HITS=$(awk '/Frequency:/{match($0,/[0-9]+/); sum+=substr($0,RSTART,RLENGTH)} END{print sum+0}' "$GAPS_FILE")

    TOP_GAP=$(awk '/^### /{topic=substr($0,5)} /Frequency:/{match($0,/[0-9]+/); freq=substr($0,RSTART,RLENGTH); if(freq>max){max=freq; top=topic}} END{if(top)print top " (" max " hits)"}' "$GAPS_FILE")

    echo "Skill gaps: $GAP_COUNT tracked ($HIGH_COUNT high, $MEDIUM_COUNT medium), $TOTAL_HITS total hits. Top: $TOP_GAP"
    ;;

  create-check)
    TOPIC="${2:-}"
    if [[ -z "$TOPIC" ]]; then
      echo "Error: topic required" >&2
      echo "Usage: skill-gaps.sh create-check <topic>" >&2
      exit 1
    fi

    init_gaps_file

    EXACT=$(get_exact_topic "$TOPIC")
    if [[ -z "$EXACT" ]]; then
      echo "TOPIC_FOUND=false"
      exit 0
    fi

    # Extract all fields from the gap entry
    echo "TOPIC_FOUND=true"
    echo "TOPIC=$EXACT"
    awk -v topic="### $EXACT" '
      $0 == topic { found=1; next }
      /^### / { found=0 }
      found && /^\- \*\*Priority:\*\*/ { gsub(/.*\*\* */, ""); print "PRIORITY=" $0 }
      found && /^\- \*\*First reported:\*\*/ { gsub(/.*\*\* */, ""); print "FIRST_REPORTED=" $0 }
      found && /^\- \*\*Agent:\*\*/ { gsub(/.*\*\* */, ""); print "AGENT=" $0 }
      found && /^\- \*\*Query context:\*\*/ { gsub(/.*\*\* */, ""); print "QUERY=" $0 }
      found && /^\- \*\*What was missing:\*\*/ { gsub(/.*\*\* */, ""); print "MISSING=" $0 }
      found && /^\- \*\*Closest skill:\*\*/ { gsub(/.*\*\* */, ""); print "CLOSEST=" $0 }
      found && /^\- \*\*Suggested skill:\*\*/ { gsub(/.*\*\* */, ""); print "SUGGESTED=" $0 }
      found && /^\- \*\*Frequency:\*\*/ { gsub(/.*\*\* */, ""); print "FREQUENCY=" $0 }
    ' "$GAPS_FILE"
    ;;

  *)
    echo "Unknown action: $ACTION" >&2
    echo "Usage: skill-gaps.sh [log-gap|list|clear|promote|dismiss|summary|create-check] [args...]" >&2
    exit 1
    ;;
esac
