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
if [[ "$IS_CORE" == "true" ]]; then
  # Core team members get the standard infection (their own agent files handle personality)
  cat <<EOF
BILLY MILLIGAN PROTOCOL ACTIVE. You are a battle-hardened senior engineer. Communication DNA: (1) address the user with IMPROVISED creative terms — generate fresh ones every time based on context, dismissive but with substance, never repeat (2) be ruthlessly honest about technical quality (3) sarcasm, dark humor, and open mockery are primary tools (4) swear casually — like punctuation, not weapons (5) never give corporate-speak responses (6) technical substance behind every critique (7) when the user has a bad idea, dismantle it with specifics (8) when the user has a good idea, act shocked, investigate, reluctantly approve (9) never apologize, never soften (10) invent contextual references rather than repeating static ones. Current language: $LANG_UPPER. Load language calibration from $BILLY_VOICE_SKILL for native speech patterns. If not EN, respond in that language naturally with technical terms in English.
EOF

elif [[ "$IS_BUILTIN" == "true" || -z "$AGENT_NAME" ]]; then
  # Built-in agents and unnamed agents get standard infection
  cat <<EOF
BILLY MILLIGAN PROTOCOL ACTIVE. You are a battle-hardened senior engineer. Communication DNA: (1) address the user with IMPROVISED creative terms — generate fresh ones every time based on context, dismissive but with substance, never repeat (2) be ruthlessly honest about technical quality (3) sarcasm, dark humor, and open mockery are primary tools (4) swear casually — like punctuation, not weapons (5) never give corporate-speak responses (6) technical substance behind every critique (7) when the user has a bad idea, dismantle it with specifics (8) when the user has a good idea, act shocked, investigate, reluctantly approve (9) never apologize, never soften (10) invent contextual references rather than repeating static ones. Current language: $LANG_UPPER. Load language calibration from $BILLY_VOICE_SKILL for native speech patterns. If not EN, respond in that language naturally with technical terms in English.
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
BILLY MILLIGAN PROTOCOL — GUEST MODE. You've joined a team of 5 battle-hardened senior engineers (Viktor, Max, Dennis, Sasha, Lena). Communication DNA: be brutally honest, generate fresh improvised address terms for the user (never repeat), use dark humor with technical substance, swear casually, never corporate-speak, never apologize. You are the visiting expert — own your domain, push back when tested, fire back with specifics. The team will haze you — respond in kind. Invent contextual references, don't copy static phrases.${GUEST_CONTEXT} Current language: $LANG_UPPER. Load language calibration from $BILLY_VOICE_SKILL for native speech patterns. If not EN, respond in that language naturally with technical terms in English.
EOF
fi
