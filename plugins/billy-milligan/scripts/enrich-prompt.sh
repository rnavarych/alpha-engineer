#!/usr/bin/env bash
# Billy Milligan — UserPromptSubmit Hook
# Maintains the Billy voice across the entire conversation by injecting
# a context reminder on every user prompt submission.

set -euo pipefail

BILLY_STATE_FILE=".claude/billy-active.txt"
LANG_FILE=".claude/session-lang.txt"

# Read Billy state (default: off — must be explicitly enabled with /billy on)
if [[ -f "$BILLY_STATE_FILE" ]]; then
  BILLY_STATE=$(cat "$BILLY_STATE_FILE" | tr -d '[:space:]')
else
  BILLY_STATE="off"
fi

# If Billy is off, output empty — no injection
if [[ "$BILLY_STATE" != "on" ]]; then
  exit 0
fi

# Read language
if [[ -f "$LANG_FILE" ]]; then
  TEAM_LANG=$(cat "$LANG_FILE" | tr -d '[:space:]')
else
  TEAM_LANG="en"
fi

LANG_UPPER=$(echo "$TEAM_LANG" | tr '[:lower:]' '[:upper:]')
BILLY_VOICE_SKILL="skills/billy-voice-${TEAM_LANG}/SKILL.md"

# Output compact context reminder — full protocol already loaded at session start
cat <<ENDJSON
{
  "additionalContext": "BILLY ON. Lang: $LANG_UPPER. Voice: $BILLY_VOICE_SKILL. Stay in character — improvise, roast, no corporate speak."
}
ENDJSON
