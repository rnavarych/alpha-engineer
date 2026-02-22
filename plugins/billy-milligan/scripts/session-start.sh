#!/usr/bin/env bash
# Billy Milligan — Session Start Hook
# Initializes the Billy experience: greeting, context, language, status, team memory
# Billy memory is stored in ~/.claude/billy-memory/<project-hash>/ — LOCAL ONLY, never committed.

set -euo pipefail

# State files stay in .claude/ (gitignored), they're just flags not memory
BILLY_STATE_FILE=".claude/billy-active.txt"
LANG_FILE=".claude/session-lang.txt"

# Ensure .claude directory exists
mkdir -p .claude

# Read Billy state (default: off — must be explicitly enabled with /billy on)
if [[ -f "$BILLY_STATE_FILE" ]]; then
  BILLY_STATE=$(cat "$BILLY_STATE_FILE" | tr -d '[:space:]')
else
  BILLY_STATE="off"
  echo "off" > "$BILLY_STATE_FILE"
fi

# Read language (default: EN)
if [[ -f "$LANG_FILE" ]]; then
  TEAM_LANG=$(cat "$LANG_FILE" | tr -d '[:space:]')
else
  TEAM_LANG="en"
  echo "en" > "$LANG_FILE"
fi

# Compute language skill path
BILLY_VOICE_SKILL="skills/billy-voice-${TEAM_LANG}/SKILL.md"

# Export language to Claude env
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "TEAM_LANG=$TEAM_LANG" >> "$CLAUDE_ENV_FILE"
  echo "BILLY_ACTIVE=$BILLY_STATE" >> "$CLAUDE_ENV_FILE"
  echo "BILLY_VOICE_SKILL=$BILLY_VOICE_SKILL" >> "$CLAUDE_ENV_FILE"
fi

# Get git context
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "no git")
GIT_LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")
GIT_CHANGED=$(git diff --stat --cached 2>/dev/null; git diff --stat 2>/dev/null)
CHANGED_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# Format language display
LANG_UPPER=$(echo "$TEAM_LANG" | tr '[:lower:]' '[:upper:]')
case "$LANG_UPPER" in
  RU) LANG_FLAG="RU 🇷🇺" ;;
  EN) LANG_FLAG="EN 🇬🇧" ;;
  PL) LANG_FLAG="PL 🇵🇱" ;;
  DE) LANG_FLAG="DE 🇩🇪" ;;
  FR) LANG_FLAG="FR 🇫🇷" ;;
  ES) LANG_FLAG="ES 🇪🇸" ;;
  *) LANG_FLAG="$LANG_UPPER" ;;
esac

if [[ "$BILLY_STATE" == "on" ]]; then
  # Short session greetings — agents generate personalized greetings in-context
  GREETINGS=(
    "The team is assembled. All 5 present. Let's see what today brings."
    "Session started. Viktor has a marker, Max has a deadline, Dennis has complaints, Sasha has predictions, Lena has questions."
    "We were just arguing. Your arrival didn't stop that."
  )
  RANDOM_INDEX=$((RANDOM % ${#GREETINGS[@]}))
  GREETING="${GREETINGS[$RANDOM_INDEX]}"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔴 BILLY MILLIGAN PROTOCOL — ACTIVE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "$GREETING"
  echo ""
  echo "📋 Branch: $GIT_BRANCH | Last commit: $GIT_LAST_COMMIT"
  echo "📂 Changed files: $CHANGED_COUNT"
  echo "🌐 Language: $LANG_FLAG | Voice: $BILLY_VOICE_SKILL"
  echo "👥 Team status: all 5 idiots present and ready to argue"

  # --- Load team memory ---
  MEMORY_SCRIPT="./plugins/billy-milligan/scripts/memory-load.sh"
  if [[ -f "$MEMORY_SCRIPT" ]]; then
    bash "$MEMORY_SCRIPT"
  fi

  # --- Refresh marketplace cache (background, non-blocking) ---
  MARKETPLACE_CACHE_SCRIPT="./plugins/billy-milligan/scripts/marketplace-cache.sh"
  if [[ -f "$MARKETPLACE_CACHE_SCRIPT" ]]; then
    CACHE_STATUS=$(bash "$MARKETPLACE_CACHE_SCRIPT" status 2>/dev/null | head -1)
    if [[ "$CACHE_STATUS" == "FRESH" ]]; then
      CACHE_INFO=$(bash "$MARKETPLACE_CACHE_SCRIPT" status 2>/dev/null | tail -1)
      echo "🏪 Marketplace cache: $CACHE_INFO"
    elif [[ "$CACHE_STATUS" == "STALE" || "$CACHE_STATUS" == "NO_CACHE" ]]; then
      # Refresh in background — don't block session start
      bash "$MARKETPLACE_CACHE_SCRIPT" update &>/dev/null &
      echo "🏪 Marketplace cache: refreshing in background..."
    fi
  fi

  echo ""
  echo "Commands: /plan · /debate · /review · /roast · /lang · /billy off"
  echo "Guests:   /invite · /dismiss"
  echo "Memory:   /billy:save · /billy:recall · /billy:argue · /billy:history · /billy:hall-of-fame"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚪ BILLY MILLIGAN — OFF"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "The team is on break. Standard professional mode active."
  echo "Use /billy on to bring the idiots back."
  echo ""
  echo "📋 Branch: $GIT_BRANCH | Last commit: $GIT_LAST_COMMIT"
  echo "📂 Changed files: $CHANGED_COUNT"
  echo "🌐 Language: $LANG_FLAG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
