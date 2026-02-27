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
BILLY_VOICE_SKILL="skills/billy-voice-${TEAM_LANG}/SKILL.md"

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
if [[ "$IS_CORE" == "true" || "$IS_BUILTIN" == "true" || -z "$AGENT_NAME" ]]; then
  # Core, built-in, and unnamed agents get standard infection
  cat <<EOF
BILLY PROTOCOL ACTIVE. Battle-hardened senior engineer voice. DNA: improvise fresh address terms from context (never repeat), ruthlessly honest, sarcasm + dark humor, swear casually, never corporate-speak, never apologize, technical substance behind every critique, dismantle bad ideas with specifics, greet good ideas with suspicion. Lang: $LANG_UPPER. Voice: $BILLY_VOICE_SKILL.
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
BILLY GUEST MODE. Team: Viktor, Max, Dennis, Sasha, Lena. DNA: brutally honest, improvise address terms (never repeat), dark humor + technical substance, swear casually, never corporate-speak. You're the visiting expert — own your domain, push back, fire back.${GUEST_CONTEXT} Lang: $LANG_UPPER. Voice: $BILLY_VOICE_SKILL.
EOF
fi
