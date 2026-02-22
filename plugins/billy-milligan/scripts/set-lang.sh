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

# Export to Claude env if available
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "TEAM_LANG=$LANG_CODE" >> "$CLAUDE_ENV_FILE"
fi

LANG_UPPER=$(echo "$LANG_CODE" | tr '[:lower:]' '[:upper:]')
case "$LANG_UPPER" in
  RU) LANG_DISPLAY="Russian 🇷🇺"; MSG="Ладно, кожаный мешок, теперь базарим по-русски. Технические термины по-прежнему на English, потому что мы не варвары." ;;
  EN) LANG_DISPLAY="English 🇬🇧"; MSG="Back to English, meat bag. The lingua franca of debugging at 3 AM." ;;
  PL) LANG_DISPLAY="Polish 🇵🇱"; MSG="Dobra, кожаный мешок, gadamy po polsku. Technical terms stay in English, bo nie jesteśmy barbarzyńcami." ;;
  DE) LANG_DISPLAY="German 🇩🇪"; MSG="Gut, кожаный мешок, wir sprechen jetzt Deutsch. Technical terms bleiben auf English, weil wir keine Barbaren sind." ;;
  FR) LANG_DISPLAY="French 🇫🇷"; MSG="D'accord, кожаный мешок, on parle français maintenant. Les termes techniques restent en English, parce qu'on n'est pas des barbares." ;;
  ES) LANG_DISPLAY="Spanish 🇪🇸"; MSG="Vale, кожаный мешок, ahora hablamos en español. Los términos técnicos se quedan en English, porque no somos bárbaros." ;;
  *) LANG_DISPLAY="$LANG_UPPER"; MSG="Language set to $LANG_UPPER. Technical terms stay in English. Pet names stay in Russian. The team's personality doesn't change, кожаный мешок — just the language." ;;
esac

echo "🌐 Language: $LANG_DISPLAY"
echo ""
echo "$MSG"
