#!/usr/bin/env bash
# Billy Milligan — Language Setter
# Usage: set-lang.sh <language-code>
# Sets the team communication language for the current session.

set -euo pipefail

LANG_FILE=".claude/session-lang.txt"
mkdir -p .claude

LANG_INPUT="${1:-en}"
LANG_CODE=$(echo "$LANG_INPUT" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

# Normalize common language names to codes
case "$LANG_CODE" in
  english) LANG_CODE="en" ;;
  russian|русский) LANG_CODE="ru" ;;
  polish|polski) LANG_CODE="pl" ;;
  german|deutsch) LANG_CODE="de" ;;
  french|français) LANG_CODE="fr" ;;
  spanish|español) LANG_CODE="es" ;;
  ukrainian|українська) LANG_CODE="uk" ;;
  japanese|日本語) LANG_CODE="ja" ;;
  chinese|中文) LANG_CODE="zh" ;;
esac

echo "$LANG_CODE" > "$LANG_FILE"

# Compute language skill path
BILLY_VOICE_SKILL="skills/billy-voice-${LANG_CODE}/SKILL.md"

# Export to Claude env if available
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "TEAM_LANG=$LANG_CODE" >> "$CLAUDE_ENV_FILE"
  echo "BILLY_VOICE_SKILL=$BILLY_VOICE_SKILL" >> "$CLAUDE_ENV_FILE"
fi

LANG_UPPER=$(echo "$LANG_CODE" | tr '[:lower:]' '[:upper:]')
case "$LANG_UPPER" in
  RU) LANG_DISPLAY="Russian 🇷🇺"; MSG="Переключились на русский. Команда теперь говорит по-русски." ;;
  EN) LANG_DISPLAY="English 🇬🇧"; MSG="Switched to English. Team now speaks English." ;;
  PL) LANG_DISPLAY="Polish 🇵🇱"; MSG="Przełączono na polski. Zespół teraz mówi po polsku." ;;
  DE) LANG_DISPLAY="German 🇩🇪"; MSG="Auf Deutsch umgestellt. Das Team spricht jetzt Deutsch." ;;
  FR) LANG_DISPLAY="French 🇫🇷"; MSG="Passage au français. L'équipe parle maintenant français." ;;
  ES) LANG_DISPLAY="Spanish 🇪🇸"; MSG="Cambiado a español. El equipo ahora habla español." ;;
  *) LANG_DISPLAY="$LANG_UPPER"; MSG="Language set to $LANG_UPPER. Technical terms stay in English. Personality doesn't change — just the language." ;;
esac

echo "🌐 Language: $LANG_DISPLAY"
echo "🗣️ Voice skill: $BILLY_VOICE_SKILL"
echo ""
echo "$MSG"
