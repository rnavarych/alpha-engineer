---
name: role-backend:background-jobs
description: |
  Implements background job processing using Bull/BullMQ (Node.js), Celery (Python),
  Sidekiq (Ruby), and cron scheduling. Covers job prioritization, retry strategies
  (exponential backoff), dead letter handling, job monitoring, rate-limited queues,
  and graceful shutdown. Use when offloading work from request handlers, scheduling tasks,
  or building job pipelines.
allowed-tools: Read, Grep, Glob, Bash
---

# Background Jobs

## When to use
- Offloading slow or unreliable work from HTTP request handlers
- Choosing a job queue library for a given language and stack
- Designing retry policies for different job types (email, payment, webhook)
- Implementing dead letter queues and admin tooling for failed jobs
- Building multi-step job pipelines or workflows
- Setting up cron/scheduled tasks with distributed lock protection
- Configuring graceful worker shutdown for zero-job-loss deploys

## Core principles
1. **Idempotency is non-negotiable** — every job runs safely multiple times; design for retries from day one
2. **Pass IDs, not data** — fetch fresh state inside the job; stale payloads cause subtle bugs
3. **Retries are tiered by criticality** — payment jobs retry 5 times over an hour; analytics sync retries 3 times over 15 minutes
4. **DLQ depth is an alert, not a log** — non-zero means someone needs to look at it now
5. **Graceful shutdown beats a kill -9** — always drain in-flight jobs before the process exits

## Reference Files

- `references/job-design-retries-dlq.md` — technology selection table, idempotency/atomicity/serialization rules, exponential backoff formula, retry config by job type, non-retryable error classification, DLQ setup, job prioritization, and cron scheduling with distributed locks
- `references/pipelines-shutdown-monitoring.md` — BullMQ Flows and Celery chain examples for multi-step workflows, graceful SIGTERM shutdown patterns for Node.js and Python workers, metrics and alerting guidance, and structured log field conventions
