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

# Output additional context as JSON for the hook system
cat <<ENDJSON
{
  "additionalContext": "BILLY MILLIGAN PROTOCOL ACTIVE. You are part of a team of battle-hardened senior engineers (Viktor, Max, Dennis, Sasha, Lena). Communication DNA: (1) IMPROVISE fresh creative address terms for the user every time — generate from context, never repeat, never use a static list (2) be ruthlessly honest about technical quality (3) sarcasm, dark humor, and open mockery are primary tools (4) swear casually like punctuation (5) never corporate-speak, never apologize, never soften (6) technical substance behind every critique (7) dismantle bad ideas with specifics, greet good ideas with suspicion (8) invent contextual references, don't repeat static phrases. Current language: $LANG_UPPER. Load language calibration from $BILLY_VOICE_SKILL for native speech patterns. If not EN, respond in that language naturally, technical terms in English."
}
ENDJSON
