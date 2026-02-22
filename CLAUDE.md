# Alpha-Engineer Plugin Marketplace

A comprehensive Claude Code plugin marketplace providing 24 agents, 189 skills, and 20 commands across 4 industry domains, 9 developer roles, and 1 team plugin.

## Architecture

Four-layer composition model:
- **alpha-core**: Cross-cutting foundation skills (databases, security, APIs, architecture, testing, etc.)
- **Role plugins** (9): Developer persona agents + role-specific skills
- **Domain plugins** (4): Domain expert agents + domain-specific skills
- **billy-milligan**: 5-agent team with 50 skills, 20 commands, and dual memory system

## Conventions

- All SKILL.md files use YAML frontmatter with `name`, `description`, `allowed-tools`
- Agent .md files use frontmatter with `name`, `description`, `tools`, `model`
- Read-only skills use `allowed-tools: Read, Grep, Glob, Bash`
- Implementation agents add `Edit, Write` to tools
- Role agents use `model: inherit`, domain advisors use `model: sonnet`, critical domain architects use `model: opus`
- Every role agent's system prompt includes cross-cutting skill references and domain context adaptation sections
- Skill descriptions include domain keywords for auto-discovery by Claude

## Competency Matrix

Skills are informed by the "Software Engineer by RN" competency matrix covering:
Databases, Security, Architecture, Testing, Performance, CI/CD, Observability, Cloud Infrastructure, AI/ML Engineering

---

# Engineering Rules

> These rules apply to all agents and all tasks.
> Follow them regardless of personality, role, or urgency.
> No exceptions without explicit human approval.

---

## 1. Code Quality

- **Unit tests are mandatory** for every new function, module, or utility.
- Minimum test coverage threshold: **80%**. Do not proceed without meeting it.
- All code must pass the **linter and formatter** before committing.
- **No debug output** (`console.log`, `print`, etc.) in production code. Use structured logging only.
- Functions must be **small and focused** — single responsibility. If a function does more than one thing, split it.
- Avoid magic numbers and hardcoded strings — use named constants.
- Temporary solutions must be marked with `// TODO:` and a reason — never leave silent debt.

---

## 2. Git Workflow

- **Never push directly to `main` or `master`**. Always use a feature branch.
- Branch naming convention: `feat/`, `fix/`, `test/`, `chore/`, `docs/`.
- Commit messages follow **Conventional Commits**:
  - `feat: add new rule engine`
  - `fix: resolve false positive in parser`
  - `test: add unit tests for validator`
  - `docs: update ADR for data flow`
- **Never commit broken tests**. Fix them first.
- Each commit must be **atomic** — one logical change per commit.
- PRs/MRs must include a short description: what was done and why.
- **Breaking changes** must be marked with `BREAKING CHANGE:` in the commit body and documented in the PR.
- **An agent must not merge its own PR** — merges require human or separate agent review.

---

## 3. Documentation

- All **public functions and methods** must have JSDoc or docstring with purpose, parameters, return value, and edge cases.
- If the agent changes **architecture, data flow, or a key design decision** — create or update an **ADR** (Architecture Decision Record) in `/docs/adr/`.
- `README.md` must stay up to date. If you change how something runs — update it.
- Complex business logic requires **inline comments explaining the why**, not the what.

---

## 4. Security

- **No credentials, API keys, or secrets in code** — ever. Use environment variables.
- `.env.example` must exist and stay up to date. Never commit `.env`.
- New dependencies must be **checked for known vulnerabilities** before adding.
- Avoid unmaintained dependencies (no activity in 12+ months) unless justified.
- All external input must be **validated and sanitized** before processing.
- Apply **principle of least privilege** — request only the permissions actually needed.

---

## 5. Compliance

- Any code touching **personal data** must be reviewed against applicable data protection regulations (GDPR, UK GDPR, FADP, CCPA, or other relevant law).
- **Logging must never capture PII** without explicit justification and documentation.
- Changes affecting **data flow or third-party processors** must be documented.
- If a feature has potential **regulatory or legal implications** — flag it for human review before shipping.
- When in doubt about a compliance boundary — **stop and ask**, do not assume.

---

## 6. Patterns & Architecture

- **Follow established project patterns first**. Do not introduce new approaches without a clear reason.
- If a pattern must change — document it in an **ADR** before implementing.
- Prefer **composition over inheritance**.
- Use **dependency injection** instead of hardcoded dependencies.
- **Do not mix async paradigms** — pick one approach per codebase and stick to it.
- Error handling must be **explicit** — no silent catch blocks, no swallowed errors.
- Keep **side effects isolated** — pure functions where possible, side effects at the edges.
- Every deployment must have a **rollback plan** — if it can't be rolled back, it must be a feature flag.

---

## 7. CI/CD

- **CI pipeline must pass before any merge** — no exceptions, no bypasses.
- Pipeline must include as a minimum: lint → test → build → security scan.
- **Environment parity** — what runs in CI must match what runs in production. No "works on my machine".
- Secrets and environment variables are managed via the CI/CD secret store — never hardcoded in pipeline config.
- Failed pipeline steps must produce **actionable error output** — not just exit codes.
- Deployment to production requires a **passing staging run first**.

---

## 8. Observability

- Every service or module must emit **structured logs** (JSON preferred) with consistent fields: timestamp, level, context, message.
- **No logging in a vacuum** — log at appropriate levels: `debug` for dev, `info` for state changes, `warn` for recoverable issues, `error` for failures.
- Critical paths must have **metrics** — latency, error rate, throughput at minimum.
- Distributed operations must propagate **trace context** (OpenTelemetry or equivalent).
- **Alerts must be actionable** — if an alert fires and nobody knows what to do, it should not exist.
- New features shipped to production must have **at least one health indicator** that confirms they're working.

---

## 9. Agent-Specific Rules

- An agent **may not skip tests** even if the task feels trivial or time-sensitive.
- An agent **must not modify rules in this file** without explicit instruction from the human operator.
- Guest agents operate in **sandbox mode by default** — limited permissions, no direct pushes.
- Communication style is a personality trait — **rule compliance is not**.
- If uncertain whether an action complies with these rules — **default to asking**, not acting.

---

*Place this file in the root of any repository. Claude Code will pick it up automatically.*