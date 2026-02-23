# Testing Pyramid and Coverage

## When to load
Load when defining test strategy ratios, coverage thresholds, or parallelization/sharding for CI.

## Test Pyramid

```
    /  E2E  \        Few, slow, expensive
   /________\
  / Integration \    Moderate count
 /______________\
/   Unit Tests   \   Many, fast, cheap
/________________\
```

### Ratios by Project Type

| Project Type | Unit | Integration | E2E |
|-------------|------|-------------|-----|
| **Web Application** | 60% | 25% | 15% |
| **REST/GraphQL API** | 70% | 25% | 5% |
| **Library/SDK** | 80% | 15% | 5% |
| **CLI Tool** | 70% | 20% | 10% |
| **Microservice** | 60% | 30% | 10% |
| **Data Pipeline** | 50% | 40% | 10% |

- **Unit tests**: Test individual functions/methods in isolation. Fast (<100ms each), deterministic, no I/O.
- **Integration tests**: Test component interactions — database, API, service boundaries, message queues.
- **E2E tests**: Test complete user flows — browser automation, full system under test.

## Coverage Types

- **Line coverage**: Which lines were executed (most common, least informative)
- **Branch coverage**: Were both branches of every `if/else` taken?
- **Path coverage**: Were all possible execution paths tested? (expensive, rarely measured)
- **Function coverage**: Were all functions called at least once?
- **Condition coverage**: Were all boolean sub-expressions tested for true and false?

### Meaningful Coverage Thresholds

| Code Category | Recommended Threshold |
|---------------|----------------------|
| Business logic / domain | 90%+ branch coverage |
| API handlers / controllers | 80%+ line coverage |
| Data access / repositories | 80%+ line coverage |
| Utility / helper functions | 90%+ branch coverage |
| Configuration / boilerplate | No minimum (don't game it) |
| Generated code | Exclude from coverage |

### Coverage Commands
```bash
# TypeScript (Vitest)
npx vitest run --coverage --coverage.thresholds.lines=80 --coverage.thresholds.branches=75

# Python (pytest-cov)
pytest --cov=src --cov-report=html --cov-fail-under=80

# Go
go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out

# Java (JaCoCo via Maven)
mvn verify  # jacoco-maven-plugin in pom.xml

# .NET
dotnet test --collect:"XPlat Code Coverage" /p:Threshold=80
```

- Use coverage to find untested code paths, not as a vanity metric
- Enforce thresholds in CI to prevent coverage regression
- Exclude test files, generated code, and configuration from coverage metrics

## Test Parallelization and Sharding

- **Jest**: `--maxWorkers=50%` for parallel test files, `--shard=1/4` for CI sharding
- **Vitest**: `--pool=threads` or `--pool=forks`, `--shard=1/4`
- **pytest**: `pytest-xdist` with `-n auto` for parallel, `--dist=loadgroup` for grouping
- **JUnit 5**: `junit.jupiter.execution.parallel.enabled=true` in properties
- **Go**: Tests run in parallel by default with `t.Parallel()`
- **Playwright**: `fullyParallel: true` in config, `--shard=1/4` for CI

### CI Sharding Strategy
```yaml
# GitHub Actions -- matrix sharding
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx jest --shard=${{ matrix.shard }}/4
```
