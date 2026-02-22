# Alpha-Engineer: Claude Code Plugin Marketplace

A comprehensive Claude Code plugin marketplace providing specialized skills, agents, and commands for software engineering teams. Informed by the **Software Engineer by RN** competency matrix.

## What's Inside

| Category | Plugins | Agents | Skills | Commands |
|----------|---------|--------|--------|----------|
| Foundation | 1 (alpha-core) | 2 | 11 | — |
| Roles | 8 | 8 | 70 | — |
| Domains | 4 | 8 | 32 | — |
| Billy Milligan | 1 | 5 | 50 | 20 |
| **Total** | **14** | **23** | **163** | **20** |

### Developer Roles
- **Senior Frontend Developer** — React, Vue, Angular, CSS, accessibility, performance
- **Senior Backend Developer** — APIs, databases, microservices, message queues
- **Senior Mobile Developer** — React Native, Flutter, iOS, Android
- **Senior DevOps Engineer** — Docker, Kubernetes, Terraform, CI/CD, monitoring, AWS, Azure, GCP
- **Senior AQA Engineer** — Test strategy, E2E, API, performance, security testing
- **Senior Architect** — System design, ADRs, scalability, tech stack, AWS/Azure/GCP architecture
- **Senior Fullstack Engineer** — End-to-end development, scaffolding, deployment
- **Senior Algorithms Engineer** — Algorithm design, data structures, dynamic programming, graph algorithms, optimization

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

### Billy Milligan — The Team Inside Your Head
5 toxic senior engineers trapped in one plugin. They argue, roast each other, and somehow deliver excellent technical decisions.

| Agent | Role | Model |
|-------|------|-------|
| **Viktor** | Senior Architect — draws boxes, quotes Fowler | opus |
| **Max** | Senior Tech Lead — ships it, asks questions later | opus |
| **Dennis** | Senior Fullstack Dev — grumpy, writes the actual code | sonnet |
| **Sasha** | Senior AQA Engineer — paranoid, everything will break | sonnet |
| **Lena** | Senior Business Analyst — sharpest person in the room | opus |

**20 commands**: `/plan`, `/debate`, `/review`, `/roast`, `/invite`, `/dismiss`, `/lang`, `/billy`, 7 memory commands (`/billy-save`, `/billy-recall`, `/billy-history`, `/billy-argue`, `/billy-context`, `/billy-forget`, `/billy-hall-of-fame`), 5 ADR commands (`/adr-new`, `/adr-list`, `/adr-review`, `/adr-status`, `/adr-supersede`)

**50 technical skills** across architecture, development, infrastructure, quality, product, and shared categories.

**Two-memory system**: Billy Memory (local, informal team chaos) + Project ADRs (formal, version-controlled decisions).

See [plugins/billy-milligan/README.md](plugins/billy-milligan/README.md) for full documentation.

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
/plan add user authentication
/debate Redis vs PostgreSQL for caching
/review src/components/Auth.tsx
/roast should we use GraphQL?
/adr-new "Database Choice"
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
| `domain-iot` | domain | 2 | 8 | MQTT, edge computing, device management |
| `domain-ecommerce` | domain | 2 | 8 | Payments, catalogs, checkout, inventory |
| `domain-fintech` | domain | 2 | 8 | Ledger design, transactions, compliance |
| `domain-healthcare` | domain | 2 | 8 | HIPAA, HL7 FHIR, PHI, EHR, telehealth |
| `billy-milligan` | team | 5 | 50 | 5 toxic engineers, 20 commands, dual memory |

## License

MIT
