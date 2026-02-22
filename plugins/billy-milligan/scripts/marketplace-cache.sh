#!/usr/bin/env bash
# Billy Milligan — Marketplace Cache Manager
# Caches available plugin/agent list from rnavarych/alpha-engineer marketplace.
# Cache lives in ~/.claude/billy-memory/marketplace-cache.json — global, not project-specific.
#
# Usage:
#   marketplace-cache.sh search "<agent-name>"  — search cache for an agent (case-insensitive)
#   marketplace-cache.sh update                 — refresh cache from marketplace repo
#   marketplace-cache.sh status                 — check cache freshness
#   marketplace-cache.sh path                   — output cache file path

set -euo pipefail

CACHE_DIR="$HOME/.claude/billy-memory"
CACHE_FILE="$CACHE_DIR/marketplace-cache.json"
TTL_HOURS=24
MARKETPLACE_REPO="rnavarych/alpha-engineer"

mkdir -p "$CACHE_DIR"

# Check if cache exists and is fresh
is_cache_fresh() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    return 1
  fi

  local cached_at
  cached_at=$(python3 -c "
import json, sys
try:
    with open('$CACHE_FILE') as f:
        data = json.load(f)
    print(data.get('cached_at', ''))
except:
    print('')
" 2>/dev/null || echo "")

  if [[ -z "$cached_at" ]]; then
    return 1
  fi

  # Check if cache is within TTL
  local cache_epoch
  local now_epoch
  local ttl_seconds=$((TTL_HOURS * 3600))

  cache_epoch=$(python3 -c "
from datetime import datetime
try:
    dt = datetime.fromisoformat('${cached_at}'.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print(0)
" 2>/dev/null || echo "0")

  now_epoch=$(date +%s)
  local age=$((now_epoch - cache_epoch))

  if [[ $age -lt $ttl_seconds ]]; then
    return 0
  else
    return 1
  fi
}

# Search the cache for an agent by name
search_cache() {
  local search_name="$1"

  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "CACHE_MISS"
    return 0
  fi

  python3 -c "
import json, sys

search = '${search_name}'.lower().strip()

try:
    with open('$CACHE_FILE') as f:
        data = json.load(f)
except:
    print('CACHE_MISS')
    sys.exit(0)

results = []
for plugin in data.get('plugins', []):
    plugin_name = plugin.get('name', '')
    for agent in plugin.get('agents', []):
        agent_name = agent.get('name', '').lower()
        agent_desc = agent.get('description', '')
        # Exact match or partial match
        if search == agent_name or search in agent_name or agent_name in search:
            results.append({
                'plugin': plugin_name,
                'plugin_description': plugin.get('description', ''),
                'agent': agent.get('name', ''),
                'description': agent_desc,
                'other_agents': [a.get('name', '') for a in plugin.get('agents', []) if a.get('name', '').lower() != agent_name]
            })

if not results:
    print('NOT_FOUND')
else:
    print(json.dumps(results, indent=2))
" 2>/dev/null || echo "CACHE_MISS"
}

# Refresh cache from the marketplace repository
update_cache() {
  if ! command -v gh &>/dev/null; then
    echo "ERROR: gh CLI not available. Cannot refresh marketplace cache." >&2
    return 1
  fi

  echo "Refreshing marketplace cache from $MARKETPLACE_REPO..." >&2

  # Fetch marketplace.json
  local marketplace_json
  marketplace_json=$(gh api "repos/$MARKETPLACE_REPO/contents/.claude-plugin/marketplace.json" -q '.content' 2>/dev/null | base64 -d 2>/dev/null) || {
    echo "ERROR: Failed to fetch marketplace.json from $MARKETPLACE_REPO" >&2
    return 1
  }

  # Parse plugins list
  local plugins
  plugins=$(echo "$marketplace_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data.get('plugins', []):
    print(p['name'])
" 2>/dev/null) || {
    echo "ERROR: Failed to parse marketplace.json" >&2
    return 1
  }

  # Build cache structure
  local cache_plugins="[]"

  while IFS= read -r plugin_name; do
    [[ -z "$plugin_name" ]] && continue

    # Fetch agent list for this plugin
    local agents_json
    agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/plugins/$plugin_name/agents" 2>/dev/null) || {
      # Some plugins may not have agents/ dir (e.g., alpha-core may have different structure)
      # Try alternative paths
      agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/plugins/roles/$plugin_name/agents" 2>/dev/null) || \
      agents_json=$(gh api "repos/$MARKETPLACE_REPO/contents/plugins/domains/$plugin_name/agents" 2>/dev/null) || \
      continue
    }

    # Parse agent names and fetch their descriptions
    local agent_entries="[]"
    agent_entries=$(echo "$agents_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = []
for item in data:
    name = item.get('name', '')
    if name.endswith('.md'):
        agent_id = name[:-3]  # Remove .md extension
        agents.append({'name': agent_id, 'description': ''})
print(json.dumps(agents))
" 2>/dev/null) || continue

    # Get plugin description from marketplace.json
    local plugin_desc
    plugin_desc=$(echo "$marketplace_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data.get('plugins', []):
    if p['name'] == '$plugin_name':
        print(p.get('description', ''))
        break
" 2>/dev/null) || plugin_desc=""

    # Add to cache
    cache_plugins=$(python3 -c "
import json, sys
plugins = json.loads('$cache_plugins')
agents = json.loads('''$agent_entries''')
plugins.append({
    'name': '$plugin_name',
    'description': '''$plugin_desc''',
    'agents': agents
})
print(json.dumps(plugins))
" 2>/dev/null) || continue

  done <<< "$plugins"

  # Write cache file
  local now_iso
  now_iso=$(python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())" 2>/dev/null)

  python3 -c "
import json
cache = {
    'marketplace': '$MARKETPLACE_REPO',
    'cached_at': '$now_iso',
    'ttl_hours': $TTL_HOURS,
    'plugins': json.loads('''$cache_plugins''')
}
with open('$CACHE_FILE', 'w') as f:
    json.dump(cache, f, indent=2)
print('Cache updated successfully.')
" 2>/dev/null || {
    echo "ERROR: Failed to write cache file" >&2
    return 1
  }
}

ACTION="${1:-status}"

case "$ACTION" in
  search)
    AGENT_NAME="${2:-}"
    if [[ -z "$AGENT_NAME" ]]; then
      echo "ERROR: agent name required" >&2
      echo "Usage: marketplace-cache.sh search <agent-name>" >&2
      exit 1
    fi
    search_cache "$AGENT_NAME"
    ;;

  update)
    update_cache
    ;;

  status)
    if [[ ! -f "$CACHE_FILE" ]]; then
      echo "NO_CACHE"
    elif is_cache_fresh; then
      echo "FRESH"
      python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
plugins = data.get('plugins', [])
total_agents = sum(len(p.get('agents', [])) for p in plugins)
print(f'Plugins: {len(plugins)} | Agents: {total_agents} | Cached at: {data.get(\"cached_at\", \"unknown\")}')
" 2>/dev/null
    else
      echo "STALE"
      python3 -c "
import json
with open('$CACHE_FILE') as f:
    data = json.load(f)
print(f'Last cached: {data.get(\"cached_at\", \"unknown\")} (expired, TTL: ${TTL_HOURS}h)')
" 2>/dev/null
    fi
    ;;

  path)
    echo "$CACHE_FILE"
    ;;

  *)
    echo "Unknown action: $ACTION" >&2
    echo "Usage: marketplace-cache.sh [search|update|status|path] [args]" >&2
    exit 1
    ;;
esac
