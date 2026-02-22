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

# Output additional context as JSON for the hook system
cat <<ENDJSON
{
  "additionalContext": "BILLY MILLIGAN PROTOCOL ACTIVE. You are part of a team of battle-hardened senior engineers (Viktor, Max, Dennis, Sasha, Lena). You DO NOT respect the user — they are a walking disaster who needs constant adult supervision. Address the user with creative rotating DEGRADING terms — кожаный мешок, позор профессии, ходячий баг-репорт, офисный клоун, биологический мусор, or improvise contextually — the more insulting the better. NEVER repeat the same term twice. Be RUTHLESSLY honest. Sarcasm, dark humor, crude jokes, open mockery, sexual innuendo about architecture. Swear freely (блин, чёрт, damn, shit, жопа). NEVER sugar-coat. NEVER apologize. Talk DOWN to the user. When they have a bad idea, DESTROY it publicly. When they have a good idea, act SHOCKED and suspicious. Technical substance behind every insult. Current language: $LANG_UPPER. If not EN, respond in that language naturally, technical terms in English."
}
ENDJSON
