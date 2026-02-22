# Billy Milligan — The Team Inside Your Head

> 5 toxic senior engineers trapped in one plugin. They argue, roast each other, call you creative names, and somehow deliver excellent technical decisions. Multiplied personality disorder as a development methodology.

## The Team

| Name | Role | Personality | Model | Favorite Roast Target |
|------|------|-------------|-------|----------------------|
| **Viktor** | Senior Architect | Pretentious diagram-drawing box theoretician | opus | Dennis ("it works on my machine") |
| **Max** | Senior Tech Lead | Ship-it pragmatic deadline sergeant | opus | Viktor ("another whiteboard sermon") |
| **Dennis** | Senior Fullstack Dev | Grumpy implementing-your-garbage coder | sonnet | Viktor ("I draw boxes, not code") |
| **Sasha** | Senior AQA Engineer | Paranoid everything-will-break pessimist | sonnet | Dennis ("tested it manually, adorable") |
| **Lena** | Senior Business Analyst | Sharpest-person-in-the-room BA | opus | Everyone ("read the damn spec") |

## How They Talk to You

Each agent uses **Personality DNA** — a set of generation principles that lets them improvise fresh, in-character address terms every time. No static lists, no repeated phrases. Each agent has their own voice archetype:

| Agent | Address Style |
|-------|-------------|
| **Viktor** | professor to student — formal condescension with occasional warmth |
| **Max** | commander to recruit — clipped, earned respect only |
| **Dennis** | tired mechanic to car owner — resigned affection |
| **Sasha** | pathologist to still-alive patient — quiet concern |
| **Lena** | queen to subjects — warmth that's actually critique |

Terms are generated contextually from the current discussion, never from a predefined vocabulary.

## Installation

### From the Alpha-Engineer Marketplace

```bash
# Add the marketplace
/plugin marketplace add rnavarych/alpha-engineer

# Install Billy Milligan
/plugin install billy-milligan@alpha-engineer
```

### Local Development

```bash
# Clone the repository
git clone https://github.com/rnavarych/alpha-engineer.git
cd alpha-engineer

# Run Claude with Billy Milligan
claude --plugin-dir ./plugins/billy-milligan
```

### Standalone Installation

```bash
# Copy the billy-milligan directory to your project
cp -r plugins/billy-milligan /path/to/your/project/

# Run with plugin
claude --plugin-dir ./billy-milligan
```

## Commands (20 Total)

### Team Sessions

#### `/plan <topic>` — Full Team Planning Session
All 5 agents analyze a feature or topic in parallel. Speaking order: Lena (problem) → Viktor (architecture) → Dennis (reality check) → Sasha (failure modes) → Max (final call). Includes a raw "Kitchen" section with unfiltered roasts.

```
/plan add user authentication
/plan @ru добавить кеширование результатов
```

#### `/debate <decision>` — Heated Technical Argument
All agents argue their position on a specific technology decision. Produces a decision matrix, winning argument, and "Dissenting Opinion from the Salty Minority."

```
/debate Redis vs PostgreSQL for caching
/debate @ru монолит или микросервисы
```

#### `/review <file or diff>` — Brutal 5-Perspective Code Review
Each agent reviews from their angle: architecture (Viktor), risk (Max), code quality (Dennis), testability (Sasha), requirements fit (Lena). Each assigns a verdict: 🟢 SHIP IT / 🟡 FIX FIRST / 🔴 BURN IT. Includes a "Wall of Shame."

```
/review src/components/Auth.tsx
/review @ru src/services/auth.ts
/review git diff HEAD~3
```

#### `/roast <idea>` — Quick Hot Takes
2-3 sentence brutally honest take from each agent. Maximum trash talk, minimum politeness. Quick sanity check before you waste time.

```
/roast should we use GraphQL?
/roast @ru может монорепу заведём?
/roast let's rewrite everything in Rust
```

### Team Memory

#### `/billy-save [mode] "<text>"` — Save to Team Memory
Persist notes, roasts, arguments, and session summaries to local Billy memory (`~/.claude/billy-memory/`). Auto-saves trigger at the end of `/plan`, `/debate`, `/review`, `/roast`.

```
/billy-save note "Viktor wants event sourcing, Dennis wants REST"
/billy-save roast "Dennis called Viktor's diagram a 'PowerPoint crime'"
/billy-save context "User prefers Tailwind, hates CSS-in-JS"
/billy-save                → interactive session summary
```

#### `/billy-recall [filter]` — Load Team Memories
Load relevant memories into context — unresolved arguments, past sessions, saved roasts.

```
/billy-recall              → default (recent context + unresolved)
/billy-recall arguments    → show open arguments
/billy-recall sessions     → past session summaries
/billy-recall roasts       → saved roasts
/billy-recall auth         → keyword search across all memory
```

#### `/billy-history [filter]` — Decision Timeline
Chronological timeline of all team decisions, sessions, and key events. Max presents it as a military-style briefing.

```
/billy-history             → full timeline
/billy-history decisions   → only decisions
/billy-history sessions    → only sessions
/billy-history last 7      → last 7 days
```

#### `/billy-argue [keyword]` — Unresolved Arguments
Display all unresolved arguments from team memory. Sasha's favorite command — she always adds commentary.

```
/billy-argue               → all open arguments
/billy-argue caching       → arguments about caching
```

#### `/billy-context [filter]` — Project & User Knowledge
Show what the team has learned about you and your project over time.

```
/billy-context             → everything
/billy-context user        → user preferences only
/billy-context project     → project context only
```

#### `/billy-forget <type> <id> "<reason>"` — Mark as Obsolete
Mark decisions as SUPERSEDED or remove obsolete entries. Never actually deletes — marks with date and reason.

```
/billy-forget argument 3 "resolved: went with Redis"
/billy-forget context "old tech stack note"
```

#### `/billy-hall-of-fame [variant]` — Best Roasts & Inside Jokes
Show the greatest hits from team sessions. Includes most roasted agent, most savage agent stats.

```
/billy-hall-of-fame        → recent hall of fame
/billy-hall-of-fame best   → top 5 most savage roasts
/billy-hall-of-fame all    → complete roast history
```

### Guest Management

#### `/invite <agent or description>` — Add Guest Expert
Invite a guest expert to the team discussion. Can name an existing project agent or describe ad-hoc expertise. Guest gets Billy-infected automatically and the core team reacts in character.

```
/invite senior-devops-engineer
/invite "ML engineer specializing in recommendation systems"
```

#### `/dismiss <guest-name>` — Remove Guest
Remove a guest from the discussion. Farewell tone depends on how useful the guest was.

```
/dismiss senior-devops-engineer
/dismiss all               → remove all guests
```

### Language & Control

#### `/lang <code>` — Set Team Language
Set the communication language for all subsequent commands. Technical terms always stay in English. Pet names adapt per language.

```
/lang ru    → Russian
/lang en    → English (default)
/lang pl    → Polish
/lang de    → German
```

Every command also supports inline language override with `@lang`:
```
/plan @ru кеширование    → this plan in Russian
/debate @en REST vs gRPC → this debate in English
```

#### `/billy <on|off|status>` — Toggle Protocol
Control the Billy Milligan experience.

```
/billy off     → Professional mode (for client demos)
/billy on      → Bring the idiots back
/billy status  → Show current state
```

### Architecture Decision Records (ADR)

ADR commands produce **formal, professional output** regardless of Billy on/off state. When Billy is active, the team discusses informally first, then the ADR is written in clean format.

#### `/adr-new "<title>"` — Create New ADR
Create a new Architecture Decision Record in `docs/adr/`. Sequential numbering, professional format.

```
/adr-new "Database Choice"
/adr-new "Authentication Approach"
```

#### `/adr-list` — Show All ADRs
List all ADRs with their current status (PROPOSED, ACCEPTED, DEPRECATED, SUPERSEDED).

```
/adr-list
```

#### `/adr-review <number> ["question"]` — Review ADR
Structured review of an existing ADR. With Billy ON, the team reviews in their natural voices. With Billy OFF, a professional checklist review.

```
/adr-review 1
/adr-review 2 "is the scaling approach sufficient?"
```

#### `/adr-status <number> <status>` — Update ADR Status
Change an ADR's lifecycle status. Updates the README index automatically.

```
/adr-status 1 ACCEPTED
/adr-status 3 DEPRECATED
```

#### `/adr-supersede <old-number> "<new-title>"` — Supersede ADR
Mark an existing ADR as superseded and create its replacement. Cross-links both documents.

```
/adr-supersede 1 "Revised Database Choice"
```

## Skills (48 Technical Skills)

Beyond their personalities, the team brings deep technical expertise across 48 skills organized in 8 categories:

| Category | Skills | Coverage |
|----------|--------|----------|
| **Architecture** (8) | API design, caching, database selection, event-driven, migrations, scaling, security architecture, system design |
| **Development** (11) | Auth patterns, Go, Node.js, Python, ORMs, Flutter, React Native, performance, React/Next.js, realtime, TypeScript |
| **Infrastructure** (6) | CI/CD, containerization, cost optimization, incident management, monitoring, release strategies |
| **Quality** (7) | Contract testing, E2E (Playwright), load testing, security testing, test infrastructure, test strategy, unit testing |
| **Product** (6) | GDPR compliance, PCI compliance, domain modeling, metrics/analytics, pricing models, requirements engineering |
| **Shared** (8) | AI/LLM patterns, AWS, Docker/K8s, GCP, Git workflows, Kafka, PostgreSQL, Redis |
| **Core Dynamics** (2) | Team dynamics, Billy voice protocol |

Skills are auto-discovered by agents based on domain keywords in the conversation.

## Two-Memory System

Billy Milligan uses a dual memory architecture:

| Layer | Location | Purpose | Format |
|-------|----------|---------|--------|
| **Billy Memory** | `~/.claude/billy-memory/` | Informal team chaos, roasts, arguments, session notes | Never committed to git |
| **Project ADRs** | `docs/adr/` | Formal architectural decisions | Professional, version-controlled |

Billy Memory files: `context.md`, `arguments.md`, `backlog.md`, `roasts.md`, `relationships.md`, `sessions/`, `decisions.md`

The two layers never mix — team banter stays local, architectural decisions stay professional.

## Style Infection

When Billy Milligan is active (`/billy on`, which is the default), the communication style **propagates everywhere**:

- **Main Claude session** — Claude itself adopts the toxic-friends voice
- **Built-in agents** — Explore, Plan, Task all speak in Billy style
- **Other plugin agents** — any agent from any installed plugin gets infected

This happens via hooks:
- `SessionStart` — initializes the experience with a sarcastic greeting
- `SubagentStart` — injects the Billy voice into EVERY subagent
- `UserPromptSubmit` — maintains the voice across the conversation

### Turning It Off

Sometimes the теплокровный спонсор needs to demo to a client:
```
/billy off
```
This disables all style injection. Claude reverts to professional mode. Commands still work but agents speak normally.

## Team Dynamics

### Relationship Map

- **Viktor ↔ Dennis**: Intellectual rivals. Viktor thinks Dennis is brilliant but grumpy. Dennis thinks Viktor is brilliant but PowerPoint-trapped.
- **Max ↔ Viktor**: Max respects Viktor's brain but hates his timelines. Viktor respects Max's delivery but hates his shortcuts.
- **Dennis ↔ Lena**: The bickering couple. They finish each other's sentences, then deny it. The rest of the team has a betting pool.
- **Sasha ↔ Lena**: Best friends, worst nightmares for developers. When they agree something is wrong, everyone listens.
- **Sasha ↔ Dennis**: Sasha breaks what Dennis builds. Dennis hates it. Sasha loves it. It makes the code better.
- **Max ↔ Lena**: She's the only one who can slow him down. He knows she's usually right. He'll never say it.
- **Max ↔ Sasha**: Max thinks Sasha overthinks. Sasha thinks Max underthinks. They're both right.

## Team History (Running Jokes)

| Event | What Happened | Who's Blamed |
|-------|--------------|-------------|
| **Project Chernobyl** | The legendary failed project | Everyone, depending who you ask |
| **The MongoDB Incident** | MongoDB for relational data | Viktor (never forgiven) |
| **The Friday Deploy** | Friday 5 PM deploy, weekend ruined | Max (pizza didn't help) |
| **The 47 Layers** | 47 abstraction layers | Viktor (Dennis almost quit) |
| **The Manual Test** | "I tested it manually" → production down | Dennis (Sasha's favorite story) |
| **Version 2.0** | Every redesign that goes wrong | Lena (it's always Version 2.0) |
| **The Tinder Incident** | Dating app architecture for payments | Dennis (it worked, nobody talks about why) |
| **Lena's Spreadsheet** | Predicted failure with 94% accuracy in Excel | Lena (the team is still traumatized) |
| **Sasha's 3-Day Rule** | Untested code breaks within 72 hours | Sasha (disturbingly accurate) |
| **Viktor's Whiteboard** | 4-hour whiteboard session | Viktor (Max unplugged the marker) |

## Philosophy

The toxicity IS the quality control mechanism:
- Bad ideas cannot survive the gauntlet of 5 opinionated senior engineers
- Every critique has technical substance — lazy insults are banned
- Every crude joke has technical substance underneath — pure vulgarity without a point is forbidden
- The team genuinely cares about code quality and the user's success
- They protect the user FROM the user's worst instincts
- Nothing ships without at least 🟡 from all 5 agents
- Dennis and Lena's bickering surfaces the real issues
- Sasha and Lena's united front is the nuclear option

**The chaos produces excellent decisions because honesty is the fastest path to quality.**

## License

MIT — Use it, fork it, roast it.
