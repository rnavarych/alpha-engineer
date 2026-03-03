---
name: billy:invite
description: |
  Invite a guest expert to the current team discussion. Can invite a specific named agent
  from the project or another plugin, or create an ad-hoc guest agent by describing the
  expertise needed. If not found locally, searches the rnavarych/alpha-engineer marketplace
  and offers to install the plugin containing that agent.
  Guests get automatically infected with Billy voice and participate
  in all team commands (/billy:plan, /billy:debate, /billy:review, /billy:roast).
  The core team reacts in character to the new arrival.
argument-hint: "<agent-name or description of expertise>"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion
---

# /billy:invite — Invite a Guest Expert

## Usage
```
/billy:invite oleg                              → find locally or in marketplace
/billy:invite oleg@alpha-engineer               → marketplace directly
/billy:invite oleg@devops-pack@alpha-engineer   → install specific plugin
/billy:invite "payment processing expert"       → create ad-hoc guest
```

## Resolution Chain

Parse the argument first:
- **Contains `@alpha-engineer`**: skip local → Step 2 (marketplace)
- **Quoted description**: skip search → Step 4 (ad-hoc)
- **Plain name**: start at Step 1 (local)

### Step 1: Local Search

Search in order:
1. `.claude/agents/{name}.md`
2. `plugins/**/agents/{name}.md` and `plugins/**/agents/*{name}*.md` (partial)

Found → register guest (`"source": "named-agent"`), go to Step 5.
Not found → Step 2.

### Step 2: Marketplace Search

```bash
# Check cache first
bash ./plugins/billy-milligan/scripts/marketplace-cache.sh search "{name}"

# On cache miss — live lookup
gh api repos/rnavarych/alpha-engineer/contents/.claude-plugin/marketplace.json -q '.content' | base64 -d
gh api "repos/rnavarych/alpha-engineer/contents/plugins/{plugin-name}/agents" -q '.[].name'

# Update cache after live lookup
bash ./plugins/billy-milligan/scripts/marketplace-cache.sh update
```

Found → Step 3. Not found → Step 4.

### Step 3: Install Prompt

**NEVER auto-install.** Read language from `.claude/session-lang.txt`.

If marketplace not yet connected, use `AskUserQuestion` to offer one-time setup:
- Explain: Alpha Engineer marketplace — 24 agents, 189 skills across 4 domains and 9 roles
- If confirmed: `claude plugin marketplace add rnavarych/alpha-engineer`
- If declined → Step 4 with message "Creating temporary agent instead"

Then show plugin install prompt via `AskUserQuestion`:
- Show: plugin name, agent name + description, other agents in same plugin
- Options: Install + Invite, or Create temporary agent
- If confirmed: `claude plugin install {plugin-name}@alpha-engineer` → register guest (`"source": "marketplace"`, `"plugin": "{plugin-name}"`)
- If declined or install fails → Step 4

All prompts adapt to session language. Technical terms stay English.

### Step 4: Ad-Hoc Guest Generation (Fallback)

Generate a creative guest persona:
- **Name**: Real human name fitting team vibe (Oleg, Andrei, Marina, Pavel, Igor, Katya, etc.)
- **Personality**: Distinct, complements/conflicts with core team — quirks, opinions, communication style
- **Expertise**: Deep domain knowledge matching user's description
- **Attitude**: Confident, opinionated, owns their domain
- **Pet Names**: 2-3 unique rotating terms (different from ALL core team members)
- **Catchphrases**: 2-3 signature lines

Set `"source": "ad-hoc"` in registration.

### Step 5: Register Guest

Create/update `.claude/billy-guests.json`:
```json
{
  "guests": [{
    "name": "Oleg",
    "expertise": "DevOps / Kubernetes",
    "personality": "Brief vibe",
    "pet_names": ["term1", "term2"],
    "invited_at": "timestamp",
    "source": "ad-hoc | named-agent | marketplace",
    "plugin": "plugin-name (marketplace only)",
    "marketplace_first_dismiss": true
  }]
}
```

### Step 6: Arrival Scene

Generate in-character team reaction. Speaking order: Lena → Viktor → Dennis → Sasha → Max → Guest introduces themselves.

**Tone by source:**
- **Local (named-agent)**: Standard arrival — old friend energy, normal hazing
- **Marketplace**: "Hired gun" — more distance, trust earned not given. Team treats them as external consultant
- **Ad-hoc**: Creative arrival — full personality, team hazes them, guest responds in kind

Output formatted confirmation:
```markdown
# 🚪 Guest Arrived: [Name]
**Expertise:** [Domain] | **Source:** [Local|Marketplace (plugin)|Ad-hoc] | **Status:** Active
[Team arrival scene]
💡 Use `/billy:dismiss [name]` to remove this guest.
```

### Rules

- Guest voice infection via SubagentStart hook is AUTOMATIC
- Core team dynamics DON'T change when guests arrive
- Multiple guests: up to 3 max. Ad-hoc guests get creative names — NEVER generic
- Lena WILL flirt with male guests — Dennis WILL get annoyed. Non-negotiable.
- **NEVER auto-install.** Every install requires explicit `AskUserQuestion` confirmation.
- **Resolution chain is strict:** Local → Marketplace → Ad-hoc. Never skip (unless `@alpha-engineer` syntax).
- **Language-aware:** All prompts respect `/lang` setting.
- **Failed installs fail gracefully** → ad-hoc fallback.
- **One plugin = multiple agents.** Installing makes ALL agents available.
- **Cache first.** TTL 24 hours.
