---
name: domain-healthcare:hl7-fhir
description: HL7 FHIR interoperability covering FHIR resources, RESTful API patterns, server implementation, SMART on FHIR authorization, CDS Hooks, Bulk Data Access, and US Core Implementation Guide profiles.
allowed-tools: Read, Grep, Glob, Bash
---

# HL7 FHIR Interoperability

## When to use
- Implementing FHIR R4 CRUD or search operations against any server
- Standing up a HAPI FHIR or Microsoft FHIR Server instance
- Building a SMART on FHIR application (EHR launch or standalone)
- Implementing a CDS Hooks service for point-of-care decision support
- Running a bulk data export for population health or quality reporting
- Validating resources against US Core Implementation Guide profiles

## Core principles
1. **Capability statement is your contract** — publish `/metadata` accurately; clients depend on it to know what you actually support
2. **Search parameters must be indexed** — unindexed searches on large datasets will time out in production; know your server's indexing model
3. **Conditional create prevents duplicates** — use `If-None-Exist` headers on POST; without them, retries create duplicate resources
4. **SMART scopes are minimum necessary** — request only the scopes the app actually needs; over-scoped tokens are a liability
5. **Bulk export is async by design** — poll the Content-Location URL; do not block a thread waiting for $export to complete

## Reference Files
- `references/fhir-resources-api.md` — core resource table, CRUD operations, search syntax with system/code, _include/_revinclude, Bundle pagination, $everything/$validate/$export operations
- `references/fhir-server-implementation.md` — HAPI FHIR setup and interceptors, Microsoft FHIR Server with Azure AD, versioning, conditional create/update, Subscription patterns, capability statement
- `references/smart-cds-bulk.md` — SMART on FHIR authorization flow, OAuth scopes, EHR and standalone launch contexts, CDS Hooks hook points and card format, Bulk Data NDJSON export, US Core profiles and USCDI alignment
