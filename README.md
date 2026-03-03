```bash
claude plugin marketplace add rnavarych/alpha-engineer
```

# Alpha-Engineer: Claude Code Plugin Marketplace

**24 agents. 191 skills. 22 commands.** Specialized engineering plugins for Claude Code across 9 developer roles, 4 industry domains, and one unhinged team of 5 senior engineers.

---

## Billy Milligan — The Team Inside Your Head

> 5 senior engineers trapped in one plugin. They deliver excellent technical decisions. Multiplied personality disorder as a development methodology.

```bash
claude plugin install billy-milligan@alpha-engineer
```


#### `/billy <on|off|status>` — Toggle Protocol
Control the Billy Milligan experience.

```
/billy off     → Professional mode (for client demos)
/billy on      → Bring the idiots back
/billy status  → Show current state
```

**22 commands** | **52 technical skills** | **5 agents with persistent memory**

| Agent | Role | Style |
|-------|------|-------|
| **Viktor** | Senior Architect | Draws boxes, quotes Fowler, never writes code |
| **Max** | Senior Tech Lead | Ships it, asks questions later |
| **Dennis** | Senior Fullstack Dev | Grumpy, writes the actual code |
| **Sasha** | Senior AQA Engineer | Paranoid, everything will break |
| **Lena** | Senior Business Analyst | Sharpest person in the room |

> **[Read the full Billy Milligan documentation](plugins/billy-milligan/README.md)** — commands, memory system, team dynamics, relationship map, and running jokes.

---

## What's Inside

| Category | Plugins | Agents | Skills | Commands |
|----------|---------|--------|--------|----------|
| Foundation | 1 (alpha-core) | 2 | 11 | -- |
| Roles | 9 | 9 | 96 | -- |
| Domains | 4 | 8 | 32 | -- |
| Billy Milligan | 1 | 5 | 52 | 22 |
| **Total** | **15** | **24** | **191** | **22** |

### Developer Roles
- **Senior Frontend Developer** — React, Vue, Angular, CSS, accessibility, performance
- **Senior Backend Developer** — APIs, databases, microservices, message queues
- **Senior Mobile Developer** — React Native, Flutter, iOS, Android
- **Senior DevOps Engineer** — Docker, Kubernetes, Terraform, CI/CD, monitoring, AWS, Azure, GCP
- **Senior AQA Engineer** — Test strategy, E2E, API, performance, security testing
- **Senior Architect** — System design, ADRs, scalability, tech stack, AWS/Azure/GCP architecture
- **Senior Fullstack Engineer** — End-to-end development, scaffolding, deployment
- **Senior Algorithms Engineer** — Algorithm design, data structures, dynamic programming, graph algorithms, optimization
- **Senior Database Engineer** — 230+ databases across 14 categories, schema design, query optimization, replication, backup/recovery, migrations

### Industry Domains
- **IoT** — MQTT, device management, edge computing, time-series data
- **E-Commerce** — Payments, catalogs, checkout, inventory, PCI compliance
- **Fintech** — Ledger design, transactions, regulatory compliance, fraud detection
- **HealthCare** — HIPAA, HL7 FHIR, PHI handling, EHR integration, telehealth

### Cross-Cutting Foundation
- Database advisor (SQL, NoSQL, Graph, Columnar, Key-Value, Time Series)
- Security advisor (OWASP, auth, encryption)
- API design (REST, GraphQL, gRPC, WebSocket)
- Architecture patterns (SOLID, DDD, CQRS, microservices)
- Testing patterns, Performance optimization, CI/CD, Observability, Cloud infrastructure
- AI/ML engineering (system design, SaaS platforms, MLOps)
- Code review, Legal compliance reviews

## Installation

### Install the entire marketplace
```bash
claude plugin marketplace add rnavarych/alpha-engineer
```

### Install individual plugins
```bash
claude plugin install alpha-core@alpha-engineer
claude plugin install role-backend@alpha-engineer
claude plugin install domain-fintech@alpha-engineer
claude plugin install billy-milligan@alpha-engineer
```

### Recommended combinations
```bash
# Backend developer working on fintech
claude plugin install alpha-core@alpha-engineer
claude plugin install role-backend@alpha-engineer
claude plugin install domain-fintech@alpha-engineer

# Frontend developer working on e-commerce
claude plugin install alpha-core@alpha-engineer
claude plugin install role-frontend@alpha-engineer
claude plugin install domain-ecommerce@alpha-engineer

# DevOps engineer for IoT platform
claude plugin install alpha-core@alpha-engineer
claude plugin install role-devops@alpha-engineer
claude plugin install domain-iot@alpha-engineer

# Any role + Billy Milligan (adds team dynamics to any setup)
claude plugin install billy-milligan@alpha-engineer
```

## Usage

### Invoke skills directly
```
/alpha-core:database-advisor
/role-backend:microservices
/domain-fintech:ledger-design
```

### Billy Milligan commands
```
/billy:plan add user authentication
/billy:debate Redis vs PostgreSQL for caching
/billy:review src/components/Auth.tsx
/billy:roast should we use GraphQL?
/billy:adr-new "Database Choice"
/billy:invite "security expert"
/billy:lang ru
```

### Invoke agents directly

```
# Role agents
/role-backend:senior-backend-developer design a REST API for user management
```

### Agents activate automatically
Claude will delegate to the appropriate agent based on your task context. For example, asking about API design while `role-backend` is installed will activate the Senior Backend Developer agent.

## Architecture

```
alpha-core (foundation) ──┐
                          ├── Combined by Claude at runtime
role-<name> (persona)  ───┤
                          │
domain-<name> (domain) ───┤
                          │
billy-milligan (team)  ───┘
```

Each layer is independent and composable. Install only what you need.

## Plugin Catalog

| Plugin | Category | Agents | Skills | Description |
|--------|----------|--------|--------|-------------|
| `alpha-core` | foundation | 2 | 11 | Cross-cutting engineering skills |
| `role-frontend` | role | 1 | 8 | React, Vue, Angular, CSS, a11y, performance |
| `role-backend` | role | 1 | 8 | APIs, databases, microservices, queues |
| `role-mobile` | role | 1 | 8 | React Native, Flutter, iOS, Android |
| `role-devops` | role | 1 | 11 | Docker, K8s, Terraform, AWS, Azure, GCP |
| `role-aqa` | role | 1 | 8 | Test strategy, E2E, API, load, security |
| `role-architect` | role | 1 | 11 | System design, ADRs, AWS/Azure/GCP architecture |
| `role-fullstack` | role | 1 | 8 | End-to-end development, scaffolding |
| `role-algorithms` | role | 1 | 8 | Algorithms, data structures, optimization |
| `role-database` | role | 1 | 26 | 230+ databases, schema design, query optimization, DBA lifecycle |
| `domain-iot` | domain | 2 | 8 | MQTT, edge computing, device management |
| `domain-ecommerce` | domain | 2 | 8 | Payments, catalogs, checkout, inventory |
| `domain-fintech` | domain | 2 | 8 | Ledger design, transactions, compliance |
| `domain-healthcare` | domain | 2 | 8 | HIPAA, HL7 FHIR, PHI, EHR, telehealth |
| `billy-milligan` | team | 5 | 52 | 5 toxic engineers, 22 commands, dual memory |

## License

MIT
