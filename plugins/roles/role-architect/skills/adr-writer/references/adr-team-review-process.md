# ADR Team Review Process

## When to load
Load when preparing an ADR for team review, running the review process asynchronously, communicating accepted decisions to stakeholders, or scheduling review checkpoints for high-impact decisions.

## Team Review Process

### Before Writing
- Discuss the decision informally with affected team members. The ADR formalizes a conversation, not a surprise.
- Gather data: benchmarks, cost estimates, team skill inventory, production metrics.

### During Review
- Share the ADR as a pull request or document for asynchronous review.
- Request review from at least two people: one who will implement the decision and one who will operate the result.
- Set a review deadline (typically 3-5 business days). Silence after the deadline is consent.
- Encourage reviewers to challenge assumptions in the Context and completeness of Consequences.

### After Acceptance
- Communicate the decision to all affected teams. A Slack message or email with a link to the ADR is sufficient.
- Add the ADR to onboarding materials so new team members understand the architectural landscape.
- Schedule a review checkpoint (e.g., 6 months) for high-impact decisions to validate that the expected consequences materialized.
