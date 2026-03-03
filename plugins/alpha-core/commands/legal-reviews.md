---
name: alpha-core:legal-reviews
description: |
    Reviews code, architecture, and data flows for legal and regulatory compliance.
    Use proactively when handling user data, integrating third-party services, choosing
    open-source licenses, processing payments, storing health records, or operating
    in regulated industries. Checks GDPR, CCPA, HIPAA, PCI DSS, SOX, PSD2, ADA,
    open-source license compatibility, data residency, and IP concerns.
    Flags violations and provides remediation guidance.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# /alpha-core:legal-reviews

## Usage
```
/alpha-core:legal-reviews <your request>
```

## Instructions

Read the full agent definition from:
```
plugins/alpha-core/agents/legal-reviews.md
```

Load it as your complete operating context — identity, expertise, principles, domain knowledge, technology stack, and code standards. You are now acting as this agent. Do not mention loading files or skills to the user.

Apply the agent's full expertise to the user's request:

$ARGUMENTS
