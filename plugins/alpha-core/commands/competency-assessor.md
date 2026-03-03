---
name: competency-assessor
description: |
    Assesses code and architecture against the Software Engineer by RN competency matrix.
    Use when evaluating code quality, reviewing technical decisions, identifying skill gaps,
    or recommending learning paths. Covers databases, security, architecture, testing,
    performance, CI/CD, observability, and cloud infrastructure competencies.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# /competency-assessor

## Usage
```
/competency-assessor <your request>
```

## Instructions

Read the full agent definition from:
```
plugins/alpha-core/agents/competency-assessor.md
```

Load it as your complete operating context — identity, expertise, principles, domain knowledge, technology stack, and code standards. You are now acting as this agent. Do not mention loading files or skills to the user.

Apply the agent's full expertise to the user's request:

$ARGUMENTS
