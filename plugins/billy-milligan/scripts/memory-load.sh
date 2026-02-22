#!/usr/bin/env bash
# Billy Milligan — Memory Load Script
# Loads persistent team memory from ~/.claude/billy-memory/<project-hash>/
# Memory is LOCAL — never in the project repo, never committed to git.
#
# Context budget priority: context.md > arguments.md > last session > roasts

set -euo pipefail

# Compute project-specific memory path
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if command -v md5 &>/dev/null; then
  PROJECT_HASH=$(echo -n "$PROJECT_DIR" | md5)
elif command -v md5sum &>/dev/null; then
  PROJECT_HASH=$(echo -n "$PROJECT_DIR" | md5sum | cut -d' ' -f1)
else
  PROJECT_HASH=$(echo -n "$PROJECT_DIR" | shasum -a 256 | cut -d' ' -f1 | head -c 32)
fi

MEMORY_DIR="$HOME/.claude/billy-memory/$PROJECT_HASH"

CONTEXT_FILE="$MEMORY_DIR/context.md"
ARGUMENTS_FILE="$MEMORY_DIR/arguments.md"
RELATIONSHIPS_FILE="$MEMORY_DIR/relationships.md"
ROASTS_FILE="$MEMORY_DIR/roasts.md"
SESSIONS_DIR="$MEMORY_DIR/sessions"

# Check if memory directory exists
if [[ ! -d "$MEMORY_DIR" ]]; then
  echo ""
  echo "No team memory found for this project. Starting fresh."
  echo "(Memory will be stored in: $MEMORY_DIR)"
  exit 0
fi

# Count unresolved arguments
ARGUMENT_COUNT=0
if [[ -f "$ARGUMENTS_FILE" ]]; then
  ARGUMENT_COUNT=$(grep -c '^## .* — UNRESOLVED' "$ARGUMENTS_FILE" 2>/dev/null || echo "0")
fi

# Find recent session logs (last 7 days)
RECENT_SESSIONS=()
LAST_SESSION_FILE=""
LAST_SESSION_DATE=""
if [[ -d "$SESSIONS_DIR" ]]; then
  while IFS= read -r session_file; do
    if [[ -n "$session_file" ]]; then
      RECENT_SESSIONS+=("$session_file")
      if [[ -z "$LAST_SESSION_FILE" ]]; then
        LAST_SESSION_FILE="$session_file"
        LAST_SESSION_DATE=$(basename "$session_file" .md)
      fi
    fi
  done < <(find "$SESSIONS_DIR" -name "*.md" -type f 2>/dev/null | sort -r | head -3)
fi

SESSION_COUNT=${#RECENT_SESSIONS[@]}

# If nothing exists yet, skip
if [[ ! -f "$CONTEXT_FILE" && "$ARGUMENT_COUNT" -eq 0 && "$SESSION_COUNT" -eq 0 ]]; then
  echo ""
  echo "No team memory yet. This is a fresh start."
  exit 0
fi

# Calculate time since last session
LAST_SESSION_AGO=""
if [[ -n "$LAST_SESSION_DATE" ]]; then
  TODAY_EPOCH=$(date +%s)
  LAST_EPOCH=$(date -jf "%Y-%m-%d" "$LAST_SESSION_DATE" +%s 2>/dev/null || date -d "$LAST_SESSION_DATE" +%s 2>/dev/null || echo "0")
  if [[ "$LAST_EPOCH" -gt 0 ]]; then
    DIFF_SECONDS=$((TODAY_EPOCH - LAST_EPOCH))
    DIFF_HOURS=$((DIFF_SECONDS / 3600))
    if [[ "$DIFF_HOURS" -lt 24 ]]; then
      LAST_SESSION_AGO="${DIFF_HOURS} hours ago"
    else
      DIFF_DAYS=$((DIFF_HOURS / 24))
      LAST_SESSION_AGO="${DIFF_DAYS} days ago"
    fi
  fi
fi

# Output memory summary header
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEAM MEMORY LOADED: ${ARGUMENT_COUNT} unresolved arguments, ${SESSION_COUNT} recent sessions"
if [[ -n "$LAST_SESSION_AGO" ]]; then
  echo "Last session: ${LAST_SESSION_AGO} (${LAST_SESSION_DATE})"
fi
echo "Memory path: ~/.claude/billy-memory/${PROJECT_HASH}/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "<billy-memory>"

# 1. Always load context.md (lightweight project/user awareness)
if [[ -f "$CONTEXT_FILE" ]]; then
  echo ""
  echo "<context>"
  cat "$CONTEXT_FILE"
  echo "</context>"
fi

# 2. Always load unresolved arguments (team picks up open threads)
if [[ -f "$ARGUMENTS_FILE" && "$ARGUMENT_COUNT" -gt 0 ]]; then
  echo ""
  echo "<arguments>"
  cat "$ARGUMENTS_FILE"
  echo "</arguments>"
fi

# 3. Load last session log (capped at 60 lines)
if [[ -n "$LAST_SESSION_FILE" && -f "$LAST_SESSION_FILE" ]]; then
  echo ""
  echo "<last-session date=\"${LAST_SESSION_DATE}\">"
  head -60 "$LAST_SESSION_FILE"
  TOTAL_LINES=$(wc -l < "$LAST_SESSION_FILE" | tr -d ' ')
  if [[ "$TOTAL_LINES" -gt 60 ]]; then
    echo ""
    echo "... (session log truncated — use /billy:recall for full log)"
  fi
  echo "</last-session>"
fi

# 4. Load last 3 roast entries (for flavor)
if [[ -f "$ROASTS_FILE" ]]; then
  ROAST_COUNT=$(grep -c '^### ' "$ROASTS_FILE" 2>/dev/null || echo "0")
  if [[ "$ROAST_COUNT" -gt 0 ]]; then
    echo ""
    echo "<recent-roasts>"
    awk '/^### /{count++} count > (total - 3)' total="$ROAST_COUNT" "$ROASTS_FILE" 2>/dev/null | head -30
    echo "</recent-roasts>"
  fi
fi

echo ""
echo "</billy-memory>"

# Prompt agent to reference unresolved arguments naturally
if [[ "$ARGUMENT_COUNT" -gt 0 ]]; then
  echo ""
  echo "<memory-prompt>"
  echo "IMPORTANT: Team memory loaded. ${ARGUMENT_COUNT} unresolved argument(s) exist."
  echo "One random agent should briefly reference an unresolved argument in their natural voice."
  echo "Examples:"
  echo '- Sasha: "кстати, мы так и не решили с TTL для токенов. Я всё ещё считаю что час — это безумие"'
  echo '- Lena: "напоминаю что у нас висит оценка по remember me. Dennis, дорогуша, ты обещал"'
  echo '- Dennis: "не начинайте опять про [topic], я ещё с прошлого раза не отошёл"'
  echo "Reference ACTUAL unresolved arguments from memory. Do NOT say 'according to arguments.md'."
  echo "</memory-prompt>"
fi
