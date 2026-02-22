#!/usr/bin/env bash
# Billy Milligan — Memory Save Helper
# Saves to ~/.claude/billy-memory/<project-hash>/ — LOCAL ONLY, never in repo.
#
# Usage:
#   memory-save.sh session-entry           — output path to today's session file (creates if needed)
#   memory-save.sh note "<text>"           — append a note to backlog.md
#   memory-save.sh roast "<text>"          — append a roast to roasts.md
#   memory-save.sh argument "<text>"       — append an argument stub to arguments.md
#   memory-save.sh context-update "<text>" — append a note to context.md
#   memory-save.sh path                    — output the memory directory path

set -euo pipefail

# Compute project-specific memory path (never inside the project repo)
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
BACKLOG_FILE="$MEMORY_DIR/backlog.md"
ROASTS_FILE="$MEMORY_DIR/roasts.md"
SESSIONS_DIR="$MEMORY_DIR/sessions"

# Ensure memory directory structure exists
mkdir -p "$SESSIONS_DIR"

# Ensure base files exist
for f in "$ARGUMENTS_FILE" "$BACKLOG_FILE" "$ROASTS_FILE"; do
  if [[ ! -f "$f" ]]; then
    touch "$f"
  fi
done

if [[ ! -f "$CONTEXT_FILE" ]]; then
  cat > "$CONTEXT_FILE" << 'CTXEOF'
# Team Context — What We Know About the User and Project

> Accumulated knowledge from team sessions. Updated automatically.
> This is the team's shared mental model. Not for git, not for the repo.

---

CTXEOF
fi

TODAY=$(date +%Y-%m-%d)
SESSION_FILE="$SESSIONS_DIR/${TODAY}.md"

ACTION="${1:-session-entry}"

case "$ACTION" in
  session-entry)
    # Create today's session file if it doesn't exist
    if [[ ! -f "$SESSION_FILE" ]]; then
      cat > "$SESSION_FILE" << EOF
# Session Log — ${TODAY}

---
EOF
    fi
    # Output the path for other tools to use
    echo "$SESSION_FILE"
    ;;

  note)
    NOTE="${2:-}"
    if [[ -z "$NOTE" ]]; then
      echo "Error: note text required" >&2
      exit 1
    fi
    echo "- [ ] [${TODAY}] ${NOTE}" >> "$BACKLOG_FILE"
    echo "Note saved to backlog."
    ;;

  roast)
    ROAST="${2:-}"
    if [[ -z "$ROAST" ]]; then
      echo "Error: roast text required" >&2
      exit 1
    fi
    TIMESTAMP=$(date +%H:%M)
    {
      echo ""
      echo "### ${TODAY} ${TIMESTAMP}"
      echo "${ROAST}"
      echo ""
    } >> "$ROASTS_FILE"
    echo "Roast saved to Hall of Fame."
    ;;

  argument)
    ARG_TEXT="${2:-}"
    if [[ -z "$ARG_TEXT" ]]; then
      echo "Error: argument text required" >&2
      exit 1
    fi
    {
      echo ""
      echo "## ${ARG_TEXT} — UNRESOLVED"
      echo ""
      echo "**Opened:** ${TODAY}"
      echo ""
    } >> "$ARGUMENTS_FILE"
    echo "Argument saved."
    ;;

  context-update)
    UPDATE="${2:-}"
    if [[ -z "$UPDATE" ]]; then
      echo "Error: update text required" >&2
      exit 1
    fi
    TIMESTAMP=$(date +%H:%M)
    {
      echo ""
      echo "---"
      echo "*Updated ${TODAY} ${TIMESTAMP}:* ${UPDATE}"
    } >> "$CONTEXT_FILE"
    echo "Context updated."
    ;;

  path)
    # Output the memory directory path (for use by other scripts/commands)
    echo "$MEMORY_DIR"
    ;;

  *)
    echo "Unknown action: $ACTION" >&2
    echo "Usage: memory-save.sh [session-entry|note|roast|argument|context-update|path] [text]" >&2
    exit 1
    ;;
esac
