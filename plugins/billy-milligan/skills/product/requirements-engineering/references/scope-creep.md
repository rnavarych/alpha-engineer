# Scope Creep

## When to load
Load when detecting scope creep signals, negotiating a scope change mid-sprint, locking release scope before a release date, or coaching a team on protecting sprint commitments.

---

## Warning Signals Checklist

**Signals from stakeholders:**
- [ ] "While we're at it, can we also...?" — classic scope addition, each one feels small
- [ ] "The customer asked for..." without a story written or estimated
- [ ] Requirements documents that grow longer between sprint reviews
- [ ] "This will only take a few hours" (from someone who isn't implementing it)
- [ ] New edge cases added after implementation starts ("oh, but what about...")

**Signals from the team:**
- [ ] Story estimated at 5 points is now "kind of done" at end of sprint but needs "a few more things"
- [ ] "We might as well add X while we're in that code"
- [ ] Stories splitting mid-sprint into 2–3 smaller stories that weren't planned
- [ ] "Discovered requirements" — things found during implementation that weren't in the ACs

**Signals from the process:**
- [ ] Sprint velocity dropped without an explanation
- [ ] Definition of Done keeps getting additions
- [ ] Release date keeps slipping by "just one more week"
- [ ] The backlog is growing faster than it's shrinking

---

## Scope Creep Response Protocol

1. **Name it** — explicitly say "this is new scope" rather than absorbing it silently
2. **Estimate it** — even a rough estimate makes the cost visible
3. **Decide consciously** — what gets cut to accommodate this? (Zero-sum in a fixed sprint)
4. **Document it** — new requirement goes into the backlog as a new story, not absorbed into an existing one
5. **Communicate it** — if it affects the release date, stakeholders need to know immediately, not at the sprint review

---

## Scope Change Negotiation Script

```
"We can add [new request] — I want to make sure we're making that decision intentionally.

If we add it to this sprint:
  Option A: [existing story] gets pushed to next sprint
  Option B: We extend the sprint by [N] days, affecting the release date
  Option C: We descope [specific AC] from this story to create room

Which would you prefer?"
```

---

## Release Scope Lock

### When to lock scope
Lock the release scope 2 weeks before release date. After lock:
- New requirements go into the NEXT release backlog
- Bug fixes: always in, no exception
- Critical security issues: always in, no exception
- Everything else: no

### Scope lock announcement template
```
Release [version] scope is locked as of [date].

Included (committed):
- [Story list]

Excluded (next release):
- [Story list]

Any new requirements discovered after this date will be added to [next release].
Exceptions require approval from [product owner] AND [engineering lead].
```

---

## Anti-Patterns

### Moving Goalposts
Releasing a sprint review and immediately getting "but can we also..." — the product is never done, the team is never satisfied. Set a freeze for feedback on a sprint's scope. New feedback goes into next sprint's backlog, not the current one.

### Silent Absorption
Team absorbs small requests without naming them as scope changes. Each one feels trivial. Cumulatively they destroy the sprint. Name every addition, however small.

---

## Quick Reference

```
Scope creep signals: "while we're at it", mid-sprint story splits, growing backlog faster than shrinking
Response protocol: name it → estimate it → decide what gets cut → communicate the impact
Negotiation: always present three options — cut something, extend timeline, or descope an AC
Scope lock: 2 weeks before release; new requirements go to next release, no exceptions
Zero-sum rule: adding to a sprint means something else leaves the sprint
```
