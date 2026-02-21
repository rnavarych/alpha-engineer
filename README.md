# Alpha-Engineer: Claude Code Plugin Marketplace

A comprehensive Claude Code plugin marketplace providing specialized skills, agents, and commands for software engineering teams. Informed by the **Software Engineer by RN** competency matrix.

## What's Inside

| Category | Plugins | Agents | Skills |
|----------|---------|--------|--------|
| Foundation | 1 (alpha-core) | 2 | 10 |
| Roles | 7 | 7 | 56 |
| Domains | 4 | 8 | 32 |
| **Total** | **12** | **17** | **106** |

### Developer Roles
- **Senior Frontend Developer** - React, Vue, Angular, CSS, accessibility, performance
- **Senior Backend Developer** - APIs, databases, microservices, message queues
- **Senior Mobile Developer** - React Native, Flutter, iOS, Android
- **Senior DevOps Engineer** - Docker, Kubernetes, Terraform, CI/CD, monitoring
- **Senior AQA Engineer** - Test strategy, E2E, API, performance, security testing
- **Senior Architect** - System design, ADRs, scalability, tech stack evaluation
- **Senior Fullstack Engineer** - End-to-end development, scaffolding, deployment

### Industry Domains
- **IoT** - MQTT, device management, edge computing, time-series data
- **E-Commerce** - Payments, catalogs, checkout, inventory, PCI compliance
- **Fintech** - Ledger design, transactions, regulatory compliance, fraud detection
- **HealthCare** - HIPAA, HL7 FHIR, PHI handling, EHR integration, telehealth

### Cross-Cutting Foundation
- Database advisor (SQL, NoSQL, Graph, Columnar, Key-Value, Time Series)
- Security advisor (OWASP, auth, encryption)
- API design (REST, GraphQL, gRPC, WebSocket)
- Architecture patterns (SOLID, DDD, CQRS, microservices)
- Testing patterns, Performance optimization, CI/CD, Observability, Cloud infrastructure
- Code review, Legal compliance reviews

## Installation

### Install the entire marketplace
```bash
claude plugin marketplace add <your-github-username>/alpha-engineer
```

### Install individual plugins
```bash
claude plugin install alpha-core@alpha-engineer
claude plugin install role-backend@alpha-engineer
claude plugin install domain-fintech@alpha-engineer
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
```

## Usage

### Invoke skills directly
```
/alpha-core:database-advisor
/role-backend:microservices
/domain-fintech:ledger-design
```

### Agents activate automatically
Claude will delegate to the appropriate agent based on your task context. For example, asking about API design while `role-backend` is installed will activate the Senior Backend Developer agent.

## Architecture

```
alpha-core (foundation) ──┐
                          ├── Combined by Claude at runtime
role-<name> (persona)  ───┤
                          │
domain-<name> (domain) ───┘
```

Each layer is independent and composable. Install only what you need.

## License

MIT
