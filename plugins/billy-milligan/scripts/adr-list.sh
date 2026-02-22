#!/usr/bin/env bash
# ADR List — Show all Architecture Decision Records with their status
# Reads docs/adr/*.md files and extracts title, status, and date.
# Also updates docs/adr/README.md index.
# Works whether Billy is ON or OFF.
#
# Usage: adr-list.sh [--update-readme]

set -euo pipefail

ADR_DIR="docs/adr"
UPDATE_README="${1:-}"

if [[ ! -d "$ADR_DIR" ]]; then
  echo "No ADR directory found. Run /adr:new to create the first ADR."
  exit 0
fi

# Find all numbered ADR files
ADR_FILES=$(ls "$ADR_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | sort || true)

if [[ -z "$ADR_FILES" ]]; then
  echo "No ADRs found. Run /adr:new \"<title>\" to create the first one."
  exit 0
fi

# Parse each ADR file
declare -a ROWS=()
while IFS= read -r adr_file; do
  [[ -z "$adr_file" ]] && continue

  BASENAME=$(basename "$adr_file" .md)
  NUM=$(echo "$BASENAME" | sed 's/^\([0-9]*\)-.*/\1/')
  NUM_PADDED=$(printf "%03d" "$((10#$NUM))")

  # Extract title from first # heading
  TITLE=$(grep '^# ADR-' "$adr_file" 2>/dev/null | head -1 | sed 's/^# ADR-[0-9]*: //' || echo "$BASENAME")

  # Extract status
  STATUS=$(awk '/^## Status/{found=1; next} found && /^[A-Z]/{print; exit} found && /^$/{next}' "$adr_file" 2>/dev/null | head -1 | tr -d '\r' || echo "UNKNOWN")

  # Extract date
  DATE=$(awk '/^## Date/{found=1; next} found && /^[0-9]/{print; exit} found && /^$/{next}' "$adr_file" 2>/dev/null | head -1 | tr -d '\r' || echo "—")

  # Format status indicator
  case "$STATUS" in
    ACCEPTED)     STATUS_ICON="✅ ACCEPTED" ;;
    PROPOSED)     STATUS_ICON="📋 PROPOSED" ;;
    DEPRECATED)   STATUS_ICON="⚠️  DEPRECATED" ;;
    SUPERSEDED*)  STATUS_ICON="🔄 $STATUS" ;;
    *)            STATUS_ICON="$STATUS" ;;
  esac

  ROWS+=("${NUM_PADDED}|${TITLE}|${STATUS_ICON}|${DATE}|${adr_file}")

done <<< "$ADR_FILES"

# Print formatted list
echo ""
echo "Architecture Decision Records"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-5s  %-45s  %-20s  %s\n" "NUM" "TITLE" "STATUS" "DATE"
echo "─────  ─────────────────────────────────────────  ────────────────────  ──────────"

for row in "${ROWS[@]}"; do
  IFS='|' read -r num title status date _file <<< "$row"
  printf "%-5s  %-45s  %-20s  %s\n" "$num" "${title:0:45}" "${status:0:20}" "$date"
done

echo ""
echo "Total: ${#ROWS[@]} ADR(s)"
echo "Use /adr:new \"<title>\" to add a new ADR."
echo ""

# Optionally update README.md index
if [[ "$UPDATE_README" == "--update-readme" ]]; then
  README="$ADR_DIR/README.md"

  # Build the index table
  TABLE="| # | Title | Status | Date |\n|---|-------|--------|------|\n"
  for row in "${ROWS[@]}"; do
    IFS='|' read -r num title status date filepath <<< "$row"
    BASENAME=$(basename "$filepath" .md)
    STATUS_CLEAN=$(echo "$status" | sed 's/[✅📋⚠️🔄] *//')
    TABLE="${TABLE}| [${num}](${BASENAME}.md) | ${title} | ${STATUS_CLEAN} | ${date} |\n"
  done

  if [[ -f "$README" ]]; then
    # Replace the table section between ## Index and ## Process
    python3 - "$README" "$TABLE" << 'PYEOF'
import sys
import re

readme_path = sys.argv[1]
new_table = sys.argv[2]

with open(readme_path, 'r') as f:
    content = f.read()

# Replace content between ## Index and ## Process (or EOF)
new_content = re.sub(
    r'(## Index\n\n).*?(\n## |\Z)',
    lambda m: m.group(1) + new_table + '\n' + (m.group(2) if m.group(2).startswith('\n##') else ''),
    content,
    flags=re.DOTALL
)

with open(readme_path, 'w') as f:
    f.write(new_content)

print("README.md index updated.")
PYEOF
  fi
fi
