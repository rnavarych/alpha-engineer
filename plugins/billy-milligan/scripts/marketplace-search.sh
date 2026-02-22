#!/usr/bin/env bash
# Billy Milligan — Marketplace Live Search
# Searches rnavarych/alpha-engineer marketplace for an agent.
# Falls back to cache, then to live GitHub API lookup.
#
# Usage:
#   marketplace-search.sh "<agent-name>"              — search by agent name
#   marketplace-search.sh "<agent-name>" "<plugin>"   — search specific plugin
#
# Output: JSON with match info or "NOT_FOUND"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_SCRIPT="$SCRIPT_DIR/marketplace-cache.sh"
MARKETPLACE_REPO="rnavarych/alpha-engineer"

AGENT_NAME="${1:-}"
TARGET_PLUGIN="${2:-}"

if [[ -z "$AGENT_NAME" ]]; then
  echo "ERROR: agent name required" >&2
  echo "Usage: marketplace-search.sh <agent-name> [plugin-name]" >&2
  exit 1
fi

# Step 1: Check cache first
cache_result=$(bash "$CACHE_SCRIPT" search "$AGENT_NAME" 2>/dev/null)

if [[ "$cache_result" != "NOT_FOUND" && "$cache_result" != "CACHE_MISS" ]]; then
  # Filter by target plugin if specified
  if [[ -n "$TARGET_PLUGIN" ]]; then
    filtered=$(echo "$cache_result" | python3 -c "
import json, sys
data = json.load(sys.stdin)
filtered = [r for r in data if r['plugin'] == '$TARGET_PLUGIN']
if filtered:
    print(json.dumps(filtered, indent=2))
else:
    print('NOT_FOUND')
" 2>/dev/null)
    echo "$filtered"
  else
    echo "$cache_result"
  fi
  exit 0
fi

# Step 2: Cache miss or stale — try live lookup
if ! command -v gh &>/dev/null; then
  echo "NOT_FOUND"
  exit 0
fi

echo "Cache miss. Searching marketplace live..." >&2

# If target plugin is specified, search only that plugin
if [[ -n "$TARGET_PLUGIN" ]]; then
  # Try direct path first
  agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/plugins/$TARGET_PLUGIN/agents" 2>/dev/null) || \
  agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/plugins/roles/$TARGET_PLUGIN/agents" 2>/dev/null) || \
  agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/plugins/domains/$TARGET_PLUGIN/agents" 2>/dev/null) || {
    echo "NOT_FOUND"
    exit 0
  }

  # Check if agent exists in this plugin
  result=$(echo "$agents_json" | python3 -c "
import json, sys
search = '$AGENT_NAME'.lower()
data = json.load(sys.stdin)
agents = []
match = None
for item in data:
    name = item.get('name', '')
    if name.endswith('.md'):
        agent_id = name[:-3]
        agents.append(agent_id)
        if search == agent_id.lower() or search in agent_id.lower():
            match = agent_id

if match:
    others = [a for a in agents if a != match]
    result = [{
        'plugin': '$TARGET_PLUGIN',
        'agent': match,
        'description': '',
        'other_agents': others
    }]
    print(json.dumps(result, indent=2))
else:
    print('NOT_FOUND')
" 2>/dev/null)

  echo "$result"
  exit 0
fi

# Full marketplace scan — search all plugins
marketplace_json=$(gh api "repos/$MARKETPLACE_REPO/contents/.claude-plugin/marketplace.json" -q '.content' 2>/dev/null | base64 -d 2>/dev/null) || {
  echo "NOT_FOUND"
  exit 0
}

plugins=$(echo "$marketplace_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data.get('plugins', []):
    src = p.get('source', '')
    print(p['name'] + '|' + src)
" 2>/dev/null)

while IFS='|' read -r plugin_name plugin_source; do
  [[ -z "$plugin_name" ]] && continue

  # Determine actual path from source
  local_path="${plugin_source#./}"

  agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/$local_path/agents" 2>/dev/null) || continue

  result=$(echo "$agents_json" | python3 -c "
import json, sys
search = '$AGENT_NAME'.lower()
data = json.load(sys.stdin)
agents = []
match = None
for item in data:
    name = item.get('name', '')
    if name.endswith('.md'):
        agent_id = name[:-3]
        agents.append(agent_id)
        if search == agent_id.lower() or search in agent_id.lower():
            match = agent_id

if match:
    others = [a for a in agents if a != match]
    result = [{
        'plugin': '$plugin_name',
        'agent': match,
        'description': '',
        'other_agents': others
    }]
    print(json.dumps(result, indent=2))
else:
    print('NOT_FOUND')
" 2>/dev/null) || continue

  if [[ "$result" != "NOT_FOUND" ]]; then
    echo "$result"
    # Also trigger a cache update in the background
    bash "$CACHE_SCRIPT" update &>/dev/null &
    exit 0
  fi

done <<< "$plugins"

echo "NOT_FOUND"
