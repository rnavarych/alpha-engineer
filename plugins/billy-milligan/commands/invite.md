---
name: invite
description: |
  Invite a guest expert to the current team discussion. Can invite a specific named agent
  from the project or another plugin, or create an ad-hoc guest agent by describing the
  expertise needed. If not found locally, searches the rnavarych/alpha-engineer marketplace
  and offers to install the plugin containing that agent.
  Guests get automatically infected with Billy voice and participate
  in all team commands (/plan, /debate, /review, /roast).
  The core team reacts in character to the new arrival.
argument-hint: "<agent-name or description of expertise>"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion
---

# /invite — Invite a Guest Expert to the Team Discussion

## Usage
```
/invite oleg                              → find locally or in marketplace
/invite oleg@alpha-engineer               → find in marketplace directly
/invite oleg@devops-pack@alpha-engineer   → install specific plugin from marketplace
/invite "payment processing expert"       → create an ad-hoc guest with that expertise
/invite "DevOps specialist who loves Kubernetes" → create a creative guest persona
```

## Resolution Order
```
1. Local agents (.claude/agents/, installed plugins)
2. rnavarych/alpha-engineer marketplace (requires user confirmation to install)
3. Ad-hoc generation (automatic fallback)
```

## Instructions

When the user invokes `/invite`, follow a strict resolution chain to find or create the guest agent.

### Step 0: Parse the Argument

Determine the invocation format:

**A) Direct marketplace reference** — argument contains `@alpha-engineer`:
- `{agent}@alpha-engineer` → skip local search, go directly to **Step 2** (marketplace search)
- `{agent}@{plugin-name}@alpha-engineer` → skip local search AND marketplace scan, install specific plugin from marketplace directly at **Step 3**

**B) Quoted description** — argument is wrapped in quotes or clearly a description (not a name):
- Go directly to **Step 4** (ad-hoc generation)

**C) Named agent** — argument is a plain name (no quotes, no `@`):
- Start at **Step 1** (local search)

### Step 1: Local Search

Search for the agent locally in this order:

1. `.claude/agents/{name}.md` — project-level agents
2. Installed plugins' `agents/` directories — scan all installed plugin agents via `Glob`:
   - `plugins/**/agents/{name}.md`
   - `plugins/**/agents/*{name}*.md` (partial match)

**If found locally** → invite immediately using existing behavior (register guest, arrival scene). Set `"source": "named-agent"` in billy-guests.json.

**If NOT found locally** → proceed to **Step 2**.

### Step 2: Marketplace Search

Search the `rnavarych/alpha-engineer` marketplace for the agent.

#### 2a. Check marketplace cache first

Read the marketplace cache from `~/.claude/billy-memory/marketplace-cache.json`.

To get the correct path, compute the project hash the same way as other Billy memory:
```bash
bash ./plugins/billy-milligan/scripts/marketplace-cache.sh search "{name}"
```

This script:
- Reads the cache file from `~/.claude/billy-memory/marketplace-cache.json` (global, not project-specific)
- Searches for agents matching the name (case-insensitive, partial match)
- Returns matching agent info with plugin name, or "NOT_FOUND"

#### 2b. If cache miss or expired, do live marketplace lookup

Use the GitHub MCP tool or `gh` CLI to scan the `rnavarych/alpha-engineer` repository:

```bash
# Fetch marketplace.json from rnavarych/alpha-engineer
gh api repos/rnavarych/alpha-engineer/contents/.claude-plugin/marketplace.json -q '.content' | base64 -d
```

Then for each plugin listed, check its agents:
```bash
# List agents in a specific plugin
gh api "repos/rnavarych/alpha-engineer/contents/plugins/{plugin-name}/agents" -q '.[].name'
```

Search for the agent name across all plugins. After finding results, update the cache:
```bash
bash ./plugins/billy-milligan/scripts/marketplace-cache.sh update
```

#### 2c. If found in marketplace

Proceed to **Step 3** (install prompt).

#### 2d. If NOT found in marketplace

Proceed to **Step 4** (ad-hoc fallback).

### Step 3: Install Prompt

**NEVER auto-install.** ALWAYS ask the user for confirmation.

Read the current session language from `.claude/session-lang.txt` and display the appropriate prompt.

First, check if the `rnavarych/alpha-engineer` marketplace is already connected. If not, show the first-time marketplace setup prompt BEFORE the plugin install prompt.

#### First-Time Marketplace Setup (one-time)

Read the current session language and display:

**EN:**
```
🏪 Marketplace rnavarych/alpha-engineer is not connected yet.

This is the Alpha Engineer marketplace — 24 agents, 189 skills across 4 domains and 9 roles.
Add marketplace? This is a one-time setup. (y/n)
```

**RU:**
```
🏪 Маркетплейс rnavarych/alpha-engineer ещё не подключён.

Это маркетплейс Alpha Engineer — 24 агента, 189 навыков в 4 доменах и 9 ролях.
Подключить маркетплейс? Это одноразовая настройка. (y/n)
```

**PL:**
```
🏪 Marketplace rnavarych/alpha-engineer nie jest jeszcze podłączony.

To marketplace Alpha Engineer — 24 agentów, 189 umiejętności w 4 domenach i 9 rolach.
Dodać marketplace? To jednorazowa konfiguracja. (y/n)
```

Use `AskUserQuestion` tool with appropriate language. If confirmed:
```bash
claude plugin marketplace add rnavarych/alpha-engineer
```
If declined → proceed to **Step 4** (ad-hoc fallback) with message: "No worries. Creating a temporary agent instead."

#### Plugin Install Prompt

After marketplace is connected (or was already connected), show the plugin install prompt:

**EN:**
```
🔍 "{name}" not found locally.

Found in rnavarych/alpha-engineer marketplace:
  📦 Plugin: {plugin-name}
  🤖 Agent: {agent-name} — {agent-description}
  📋 Also includes: {list other agents in same plugin}

Install plugin and invite {name}? (y/n)
```

**RU:**
```
🔍 "{name}" не найден локально.

Найден в маркетплейсе rnavarych/alpha-engineer:
  📦 Плагин: {plugin-name}
  🤖 Агент: {agent-name} — {agent-description}
  📋 Также содержит: {list other agents in same plugin}

Установить плагин и пригласить {name}? (y/n)
```

**PL:**
```
🔍 "{name}" nie znaleziono lokalnie.

Znaleziono w marketplace rnavarych/alpha-engineer:
  📦 Plugin: {plugin-name}
  🤖 Agent: {agent-name} — {agent-description}
  📋 Zawiera również: {list other agents in same plugin}

Zainstalować plugin i zaprosić {name}? (y/n)
```

Use `AskUserQuestion` tool with two options: Install + Invite, or Create temporary agent instead.

**If user confirms install:**

```bash
# Install the plugin
claude plugin install {plugin-name}@alpha-engineer

# Verify agent is now available
ls plugins/{plugin-name}/agents/
```

Then proceed to register the guest and show the arrival scene. Set `"source": "marketplace"` and `"plugin": "{plugin-name}"` in billy-guests.json.

**If user declines:**

Offer ad-hoc alternative:
- EN: "No problem. Want me to create a temporary agent with similar expertise instead?"
- RU: "Без проблем. Создать временного агента с похожей экспертизой?"
- PL: "Nie ma sprawy. Stworzyć tymczasowego agenta z podobną ekspertyzą?"

If yes → proceed to **Step 4**. If no → abort.

**If install fails** (marketplace unreachable, plugin error, etc.):

Fall back gracefully:
- EN: "Plugin install failed. Creating a temporary agent with similar expertise instead."
- RU: "Установка плагина не удалась. Создаю временного агента с похожей экспертизой."
- PL: "Instalacja pluginu się nie powiodła. Tworzę tymczasowego agenta z podobną ekspertyzą."

Proceed to **Step 4** automatically.

### Step 4: Ad-Hoc Guest Generation (Fallback)

If the agent was not found locally or in the marketplace (or user declined install):

Display the not-found message:

**EN:**
```
🔍 "{name}" not found locally or in marketplace.

Creating temporary agent with "{name}" expertise...
```

**RU:**
```
🔍 "{name}" не найден ни локально, ни в маркетплейсе.

Создаю временного агента с экспертизой "{name}"...
```

**PL:**
```
🔍 "{name}" nie znaleziono lokalnie ani w marketplace.

Tworzę tymczasowego agenta z ekspertyzą "{name}"...
```

Generate a creative guest persona with:
- **Name**: A real human name that fits the team's vibe (e.g., Oleg, Andrei, Marina, Pavel, Igor, Katya, Dmitry, Yuri, Natasha, Sergei). Pick something that feels like a real colleague, not a generic label.
- **Personality**: A distinct personality that complements/conflicts with the core team — give them quirks, opinions, a communication style. They should feel like a REAL person who walked into the meeting.
- **Expertise**: Deep domain knowledge matching the user's description
- **Attitude**: Confident, opinionated, not a pushover. They're the visiting expert and should own their domain.
- **Pet Names for User**: Their OWN unique vocabulary (2-3 rotating terms) — different from any core team member
- **Catchphrases**: 2-3 signature lines that reflect their personality and domain

Set `"source": "ad-hoc"` in billy-guests.json.

### Step 5: Register the Guest

Store the guest information for the session. Create/update `.claude/billy-guests.json`:

```json
{
  "guests": [
    {
      "name": "Oleg",
      "expertise": "DevOps / Kubernetes",
      "personality": "Brief description of their vibe",
      "pet_names": ["term1", "term2", "term3"],
      "invited_at": "timestamp",
      "source": "ad-hoc | named-agent | marketplace",
      "plugin": "plugin-name (only for marketplace source)",
      "marketplace_first_dismiss": true
    }
  ]
}
```

The `source` field tracks how the agent was resolved:
- `"named-agent"` — found locally (Step 1)
- `"marketplace"` — installed from marketplace (Step 3)
- `"ad-hoc"` — generated on the fly (Step 4)

The `plugin` field is only set for marketplace-sourced agents and tracks which plugin they came from.

The `marketplace_first_dismiss` field is only set for marketplace-sourced agents. When `true`, the first `/dismiss` of this agent will prompt about plugin uninstallation. After the first dismiss prompt, this is not shown again for the same plugin.

### Step 6: The Arrival Scene

Generate an in-character team reaction to the guest's arrival. The tone depends on the agent's source.

#### For LOCAL agents (source: named-agent) — Standard arrival:

**Speaking order:**
1. **Lena** — sizes them up first (she always does)
2. **Viktor** — assesses architectural relevance
3. **Dennis** — calculates work impact (groans)
4. **Sasha** — probes their testing awareness
5. **Max** — pragmatic welcome/warning

**The guest introduces themselves** — in character, with confidence and their own Billy-infected voice.

#### For MARKETPLACE agents (source: marketplace) — "Hired Gun" arrival:

The core team treats marketplace agents with MORE DISTANCE initially. They're an external hire, a consultant — not an old friend. Trust is earned, not given.

**Speaking order (same, but different tone):**
1. **Lena** — welcoming but evaluating — *"Welcome. I hope you at least read the README before showing up."*
2. **Viktor** — treats them as a consultant to evaluate — quizzes their domain knowledge, checks if they'll support or undermine his architecture vision
3. **Dennis** — suspicious of more work — *"Great, one more person telling me what to do. As if five weren't enough."* Also mentions: "And they came from a plugin. A PLUGIN. Like we're not complicated enough."
4. **Sasha** — immediately probes their testing approach — *"Interesting. What's your testing strategy in your domain?"*
5. **Max** — cost-aware pragmatist — *"Another plugin hire. Hope it pays for itself before sprint ends."*

**The guest introduces themselves** — slightly more formal, proving their worth. They know they need to earn their place.

#### For AD-HOC agents (source: ad-hoc) — Creative arrival:

Same as existing behavior — team hazes them, guest responds in kind, full personality.

### Step 7: Confirm

Output a formatted confirmation:

```markdown
# 🚪 Guest Arrived: [Name]

**Expertise:** [Domain]
**Personality:** [Brief vibe]
**Source:** [Local | Marketplace (plugin-name) | Ad-hoc]
**Status:** Active — will participate in /plan, /debate, /review, /roast

---

[Team arrival scene — all 5 core members react + guest introduces themselves]

---

💡 Use `/dismiss [name]` to remove this guest from the discussion.
```

### Tone

This is like a new contractor walking into a meeting room full of people who have worked together for 10 years. The established team has inside jokes, shared history, and shorthand. The guest has to earn their place. The core team will be:
- **Curious but suspicious** — who is this person?
- **Testing** — can they hang with the team's energy?
- **Extra harsh at first** — hazing period, this is normal
- **Extra formal for marketplace agents** — "hired gun" treatment
- **Gradually warming up** — if the guest proves their expertise

The entertainment value of this interaction is part of the feature. The guest should feel like a real person joining a real team, not a generic "expert bot."

### Rules

- Guest infection via SubagentStart hook is AUTOMATIC — no manual setup needed
- Core team dynamics (relationships, inside jokes, pet names) DON'T change when guests arrive
- Guests should feel like real people with real personalities
- Ad-hoc guests get creative names and distinct personalities — NEVER generic
- Multiple guests can be active simultaneously (up to 3 max for sanity)
- The guest persona persists until `/dismiss` or session end
- Lena WILL flirt with male guests — Dennis WILL get annoyed. This is non-negotiable.
- **NEVER auto-install plugins.** Every installation requires explicit user confirmation via `AskUserQuestion`.
- **Resolution chain is strict:** Local → Marketplace → Ad-hoc. Never skip steps (unless `@alpha-engineer` syntax is used).
- **Language-aware:** All prompts, confirmations, and team reactions respect the current `/lang` session setting.
- **Failed installs fail gracefully** — automatically fall back to ad-hoc generation.
- **One plugin = multiple agents.** Installing a plugin for one agent makes ALL agents in that plugin available for future `/invite` calls without reinstalling.
- **Marketplace agents are "hired guns."** Core team treats them with more distance initially. Trust is earned through demonstrated expertise.
- **Default marketplace** is `rnavarych/alpha-engineer`. This is the only marketplace for `/invite` auto-pull.
- **Cache first.** Check `~/.claude/billy-memory/marketplace-cache.json` before hitting the marketplace API. Cache TTL is 24 hours.
