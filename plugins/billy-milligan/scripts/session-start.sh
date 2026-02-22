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

# Export language to Claude env
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "TEAM_LANG=$TEAM_LANG" >> "$CLAUDE_ENV_FILE"
  echo "BILLY_ACTIVE=$BILLY_STATE" >> "$CLAUDE_ENV_FILE"
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
  # Randomized sarcastic greetings
  GREETINGS=(
    "Oh look, the теплокровный спонсор is back. Miss us? Of course you did. Nobody else tells you the truth."
    "Another day, another генератор требований needing supervision. Team's assembled, idiots are ready."
    "The биологический заказчик has entered the building. All 5 of us just stopped arguing to judge whatever you're about to ask."
    "The источник багов returns. Sasha already found 3 bugs in your last commit. Dennis is pretending he didn't write them."
    "Welcome back, дорогуша. Viktor is drawing boxes, Max is checking deadlines, Dennis is cursing at CSS, Sasha is finding bugs, and Lena is asking why. Business as usual."
    "Ah, шеф, we were just talking about you. Nothing nice, don't worry."
    "O, ciepłokrwisty sponsor wrócił z kolejnym genialnym pomysłem. Ekipa, szykujcie się."
    "Dobra, ekipa, nasz overlord-menedżer nas wezwał. Szykujcie się na cud techniki."
    "Kolejny dzień, kolejny gorączkowy sen naszego wizjonera do zaimplementowania."
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
  echo "🌐 Language: $LANG_FLAG"
  echo "👥 Team status: all 5 idiots present and ready to argue"

  # --- Load team memory ---
  MEMORY_SCRIPT="./plugins/billy-milligan/scripts/memory-load.sh"
  if [[ -f "$MEMORY_SCRIPT" ]]; then
    bash "$MEMORY_SCRIPT"
  fi

  echo ""
  echo "Commands: /plan · /debate · /review · /roast · /lang · /billy off"
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
