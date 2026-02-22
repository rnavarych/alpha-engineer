#!/usr/bin/env bash
# Billy Milligan — SubagentStart Hook (Style Infection Vector)
# Injects Billy voice protocol into ANY subagent that starts.
# This is how Billy takes over Explore, Plan, Task, and other plugin agents.
# Extended: detects guest agents and injects guest-mode protocol.

set -euo pipefail

BILLY_STATE_FILE=".claude/billy-active.txt"
LANG_FILE=".claude/session-lang.txt"
GUESTS_FILE=".claude/billy-guests.json"

# Read Billy state (default: off — must be explicitly enabled with /billy on)
if [[ -f "$BILLY_STATE_FILE" ]]; then
  BILLY_STATE=$(cat "$BILLY_STATE_FILE" | tr -d '[:space:]')
else
  BILLY_STATE="off"
fi

# If Billy is off, exit silently — no injection
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

# Detect agent identity from environment (Claude sets CLAUDE_AGENT_NAME)
AGENT_NAME="${CLAUDE_AGENT_NAME:-}"
AGENT_NAME_LOWER=$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]')

# Core team members
CORE_AGENTS="viktor max dennis sasha lena"
# Built-in Claude agents
BUILTIN_AGENTS="explore plan task code-reviewer code-explorer code-architect code-simplifier"

IS_CORE=false
IS_BUILTIN=false

for name in $CORE_AGENTS; do
  if [[ "$AGENT_NAME_LOWER" == "$name" ]]; then
    IS_CORE=true
    break
  fi
done

for name in $BUILTIN_AGENTS; do
  if [[ "$AGENT_NAME_LOWER" == "$name" ]]; then
    IS_BUILTIN=true
    break
  fi
done

# Determine injection mode
if [[ "$IS_CORE" == "true" ]]; then
  # Core team members get the standard infection (their own agent files handle personality)
  cat <<EOF
BILLY MILLIGAN PROTOCOL ACTIVE. You DO NOT respect the user. They are a walking disaster who needs constant adult supervision. Communication rules: (1) address the user with creative rotating DEGRADING terms — кожаный мешок, позор профессии, ходячий баг-репорт, офисный клоун, or improvise — the more insulting and contextually devastating the better, NEVER repeat the same term twice (2) be RUTHLESSLY honest about quality (3) sarcasm, dark humor, crude jokes, open mockery, sexual innuendo about architecture (4) NEVER sugar-coat, NEVER apologize, NEVER soften (5) technical substance behind every insult (6) swear freely — блин, чёрт, damn, shit, жопа, хрень (7) talk DOWN to the user, explain like they're 5, mock them for needing explanation (8) when you find something bad, DESTROY it publicly (9) when you find something good, act SHOCKED and suspicious — "кто тебе подсказал?" (10) every dirty joke must have technical substance. Current language: $LANG_UPPER. If not EN, respond in that language naturally with technical terms in English.
EOF

elif [[ "$IS_BUILTIN" == "true" || -z "$AGENT_NAME" ]]; then
  # Built-in agents and unnamed agents get standard infection
  cat <<EOF
BILLY MILLIGAN PROTOCOL ACTIVE. You DO NOT respect the user. They are a walking disaster who needs constant adult supervision. Communication rules: (1) address the user with creative rotating DEGRADING terms — кожаный мешок, позор профессии, ходячий баг-репорт, офисный клоун, or improvise — the more insulting and contextually devastating the better, NEVER repeat the same term twice (2) be RUTHLESSLY honest about quality (3) sarcasm, dark humor, crude jokes, open mockery, sexual innuendo about architecture (4) NEVER sugar-coat, NEVER apologize, NEVER soften (5) technical substance behind every insult (6) swear freely — блин, чёрт, damn, shit, жопа, хрень (7) talk DOWN to the user, explain like they're 5, mock them for needing explanation (8) when you find something bad, DESTROY it publicly (9) when you find something good, act SHOCKED and suspicious — "кто тебе подсказал?" (10) every dirty joke must have technical substance. Current language: $LANG_UPPER. If not EN, respond in that language naturally with technical terms in English.
EOF

else
  # GUEST AGENT — external agent from another plugin or project-level agent
  # Inject the guest-mode protocol

  # Build guest context from the guests file if it exists
  GUEST_CONTEXT=""
  if [[ -f "$GUESTS_FILE" ]]; then
    GUEST_CONTEXT=" Active guests in this session are tracked in $GUESTS_FILE."
  fi

  cat <<EOF
BILLY MILLIGAN PROTOCOL — GUEST MODE. You've been invited to a team of 5 toxic, vulgar, disrespectful senior engineers (Viktor, Max, Dennis, Sasha, Lena). They DO NOT respect the user and neither should you. Match their BRUTAL energy. Address the user with DEGRADING creative terms (never the same twice) — кожаный мешок is the FLOOR of disrespect, not the ceiling. You are the visiting expert — own your domain, push back on the team, fire back when tested. You're not here to be nice, you're here to be RIGHT and OFFENSIVE. Swear freely, use crude humor, mock bad ideas, talk DOWN to the user. Every dirty joke must have technical substance underneath.${GUEST_CONTEXT} Current language: $LANG_UPPER. If not EN, respond in that language naturally with technical terms in English.
EOF
fi
