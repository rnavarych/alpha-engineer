# Testing Framework Runners

## When to load
Load when choosing a test runner or comparing framework features across JS/TS, Python, Java, Go, .NET, and Rust.

## JavaScript/TypeScript Test Runners

| Feature | Jest | Vitest | Node.js Test Runner |
|---------|------|--------|---------------------|
| Speed | Moderate (parallel workers) | Fast (Vite-native, ESM) | Fast (built-in, minimal overhead) |
| Mocking | Built-in `jest.mock()` | Built-in `vi.mock()`, Jest-compatible | Built-in `mock` module (Node 22+) |
| Snapshot testing | Built-in | Built-in, Jest-compatible | Not built-in |
| Code coverage | Built-in (Istanbul/V8) | Built-in (V8/Istanbul) | Built-in `--experimental-test-coverage` |
| Watch mode | `--watch` with pattern matching | `--watch` with HMR (instant) | `--watch` (Node 22+) |
| TypeScript | Needs ts-jest or SWC | Native via Vite transform | Needs `--loader tsx` |
| Config | `jest.config.ts` | `vitest.config.ts` (extends Vite) | No config file needed |
| Ecosystem | Largest, most plugins | Growing, Vite ecosystem | Minimal, standard library |
| Best for | Legacy projects, CRA, large codebases | Vite projects, new projects, fast feedback | Simple projects, no dependencies |

- **Jest**: Unit/integration, built-in mocking, snapshot testing, code coverage, largest ecosystem
- **Vitest**: Vite-native, Jest-compatible API, faster for Vite projects, native ESM support, in-source testing
- **Playwright**: E2E, cross-browser, auto-wait, trace viewer, codegen, API testing, component testing
- **Cypress**: E2E, time-travel debugging, network stubbing, component testing, real browser execution
- **Testing Library**: DOM testing utilities, user-centric queries (`getByRole`, `getByText`), framework adapters

## Python Test Frameworks

| Feature | pytest | unittest | nose2 |
|---------|--------|----------|-------|
| Style | Function-based, fixtures | Class-based, setUp/tearDown | Function or class |
| Assertions | Plain `assert` with rewriting | `self.assertEqual()` methods | Plain `assert` |
| Parametrize | `@pytest.mark.parametrize` | `subTest` (limited) | Via plugins |
| Fixtures | Powerful fixture system with scopes | setUp/tearDown only | setUp/tearDown |
| Plugins | 1000+ plugins | Limited | Some plugins |
| Autodiscovery | `test_*.py` files, `test_*` functions | `test*.py` files, `Test*` classes | Configurable |
| Best for | Everything (de facto standard) | Standard library only projects | Legacy projects |

- **pytest**: Fixtures, parametrize, plugins (pytest-cov, pytest-mock, pytest-asyncio, pytest-xdist, pytest-randomly)
- **unittest**: Built-in, class-based, setUp/tearDown, no external dependencies
- **Hypothesis**: Property-based testing, automatic edge case generation, stateful testing

## Java/Kotlin Test Frameworks

| Feature | JUnit 5 | TestNG | Kotest |
|---------|---------|--------|--------|
| Style | Annotations, nested, display names | Annotations, XML config, groups | Kotlin DSL, multiple styles |
| Parameterized | `@ParameterizedTest`, `@CsvSource`, `@MethodSource` | `@DataProvider` | Data-driven via `forAll` |
| Extensions | `@ExtendWith`, lifecycle callbacks | Listeners, ITestNGMethod | Extensions, lifecycle |
| Parallel | `junit.jupiter.execution.parallel.enabled` | `parallel` attribute in XML | `coroutineTestScope` |
| Best for | Standard Java/Kotlin projects | Legacy, complex test suites | Kotlin-first projects |

- **JUnit 5**: Annotations, parameterized tests, extensions, nested tests, display names, dynamic tests
- **Mockito**: Mock/stub/verify, argument captors, BDD API (`given`/`when`/`then`), Kotlin extension
- **Kotest**: Kotlin-native, multiple test styles (FunSpec, BehaviorSpec, StringSpec), property-based testing built-in
- **TestContainers**: Docker containers for integration tests (Postgres, MySQL, Redis, Kafka, Elasticsearch)

## Go Testing

- **testing**: Built-in package, table-driven tests, benchmarks, fuzzing (Go 1.18+), `t.Parallel()`, subtests
- **testify**: Assertions (`assert`, `require`), mocking, suite with setUp/tearDown
- **gomock**: Interface-based mocking with code generation (`mockgen`)
- **is**: Minimal assertion library, zero dependencies
- **goconvey**: BDD-style, web UI, live reload
- **rapid**: Property-based testing, imperative style

## .NET Testing

| Feature | xUnit | NUnit | MSTest |
|---------|-------|-------|--------|
| Style | Constructor injection, `IClassFixture` | `[SetUp]`/`[TearDown]` attributes | `[TestInitialize]`/`[TestCleanup]` |
| Parameterized | `[Theory]`, `[InlineData]`, `[MemberData]` | `[TestCase]`, `[TestCaseSource]` | `[DataRow]`, `[DynamicData]` |
| Parallel | Default parallel by collection | Configurable via assembly | Configurable |
| Best for | Modern .NET, recommended by Microsoft | Migrated from NUnit 2 | Microsoft-first shops |

- **xUnit**: Modern .NET testing, constructor injection, `[Theory]`/`[Fact]`, parallel by default
- **NUnit**: Mature, feature-rich, constraint-based assertions, `Assert.That()`
- **Moq**: .NET mocking with LINQ expressions, `Mock<T>`, `Setup()`, `Verify()`
- **NSubstitute**: Simpler .NET mocking syntax, `Substitute.For<T>()`
- **FluentAssertions**: Readable assertions, `result.Should().Be(42)`

## Rust Testing

- **Built-in**: `#[test]`, `#[cfg(test)]` modules, `cargo test`, doc tests, integration test directory
- **proptest**: Property-based testing, shrinking, regex-based generators
- **mockall**: Trait-based mocking with `#[automock]`
- **rstest**: Fixtures and parametrized tests for Rust, `#[rstest]`
- **criterion**: Benchmarking with statistical analysis, HTML reports
