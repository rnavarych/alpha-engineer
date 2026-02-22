#!/usr/bin/env bash
# Billy Milligan — Toggle on/off/status
# Usage: billy-toggle.sh <on|off|status>

set -euo pipefail

BILLY_STATE_FILE=".claude/billy-active.txt"
LANG_FILE=".claude/session-lang.txt"
mkdir -p .claude

ACTION="${1:-status}"

# Read current state
if [[ -f "$BILLY_STATE_FILE" ]]; then
  CURRENT_STATE=$(cat "$BILLY_STATE_FILE" | tr -d '[:space:]')
else
  CURRENT_STATE="off"
fi

# Read language
if [[ -f "$LANG_FILE" ]]; then
  TEAM_LANG=$(cat "$LANG_FILE" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
else
  TEAM_LANG="EN"
fi

case "$ACTION" in
  off)
    echo "off" > "$BILLY_STATE_FILE"
    if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
      echo "BILLY_ACTIVE=off" >> "$CLAUDE_ENV_FILE"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚪ BILLY MILLIGAN — DEACTIVATED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Billy Milligan has left the building."
    echo "You're on your own now, теплокровный спонсор. Try not to break anything."
    echo ""
    echo "Standard professional mode active. No more roasting."
    echo "Use /billy on when you miss the abuse."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
  on)
    echo "on" > "$BILLY_STATE_FILE"
    if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
      echo "BILLY_ACTIVE=on" >> "$CLAUDE_ENV_FILE"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔴 BILLY MILLIGAN — REACTIVATED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The idiots are back. Did you miss us? Of course you did."
    echo "Nobody else has the guts to tell you your code is garbage."
    echo ""
    echo "🌐 Language: $TEAM_LANG"
    echo "👥 Team: Viktor · Max · Dennis · Sasha · Lena"
    echo "Commands: /plan · /debate · /review · /roast · /lang"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
  status)
    if [[ "$CURRENT_STATE" == "on" ]]; then
      STATUS_ICON="🔴 ACTIVE"
    else
      STATUS_ICON="⚪ OFF"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "BILLY MILLIGAN STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "State:    $STATUS_ICON"
    echo "Language: $TEAM_LANG"
    echo ""
    echo "Agents loaded:"
    echo "  Viktor  — Senior Architect       (opus)   — drawing boxes"
    echo "  Max     — Senior Tech Lead        (opus)   — checking deadlines"
    echo "  Dennis  — Senior Fullstack Dev    (sonnet) — cursing at CSS"
    echo "  Sasha   — Senior AQA Engineer     (sonnet) — finding bugs"
    echo "  Lena    — Senior Business Analyst (opus)   — asking why"
    echo ""
    echo "Commands: /plan · /debate · /review · /roast · /lang · /billy"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
  *)
    echo "Usage: /billy <on|off|status>"
    echo "  on     — Bring the team back"
    echo "  off    — Silence the idiots (professional mode)"
    echo "  status — Show current state"
    ;;
esac
