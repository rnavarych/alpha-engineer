# Testing in Production

## When to load
When implementing canary deployments, feature flags, shadow traffic, or synthetic monitoring; when planning safe production validation strategies; when setting up dark launching or gradual rollouts.

## Feature Flags
- Use LaunchDarkly, Unleash, or Flagsmith to control feature exposure.
- Enable features for internal users first. Gradually roll out to 1%, 5%, 20%, 100%.
- Write tests that run against both flag-on and flag-off states.
- Test flag configuration changes themselves — a bad flag config can be as damaging as bad code.

## Canary Deployments
- Route 1-5% of production traffic to new version. Monitor error rates and latency.
- Automated rollback if error rate exceeds threshold (>0.1% increase).
- Run synthetic tests against canary instances to verify functionality before expanding rollout.

## Shadow Traffic
- Duplicate production traffic and replay against new version without serving results to users.
- Compare responses between production and shadow. Flag divergences for investigation.
- Tools: Diffy (Twitter), Scientist (GitHub), shadow-proxy, traffic mirroring in Envoy/Nginx.

## Dark Launching
- Deploy new code paths but do not expose them to users.
- Execute new code path in parallel with old, compare results, log divergences.
- Validate new implementation against real production data before cutover.
- Reduces risk of big-bang feature launches.

## Synthetic Monitoring
- Run business-critical user flows as synthetic transactions every 1-5 minutes in production.
- Alert immediately when flows fail. Do not wait for user reports.
- Tools: Checkly, Datadog Synthetics, New Relic Scripted Browser, AWS CloudWatch Synthetics.

## AI-Assisted Test Generation

### Tooling Overview
- **Codium (TestGPT)**: Analyzes function signatures, implementation, and docstrings to generate tests. Generates happy path, edge cases, and error cases. VS Code and JetBrains plugin. Review all suggestions before committing.
- **Diffblue Cover**: Java-specific automated unit test generation. Runs in CI to regenerate tests when code changes. Best for brownfield Java codebases with low coverage.
- **GitHub Copilot for Tests**: Describe intent in comments, Copilot completes the test body. Strong at boilerplate, weak at complex domain logic. Always verify correctness of generated assertions.
- **Claude Code AI Test Review**: Review test quality — missing edge cases, incorrect assertions, test smell. Generate property-based test cases from function signatures. Generate test data: "generate 20 test credit card numbers covering decline codes, international cards, and prepaid cards."
