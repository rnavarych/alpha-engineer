# Advanced Testing Techniques

## When to load
Load when implementing property-based testing, mutation testing, or snapshot testing strategies.

## Property-Based Testing

Test with randomly generated inputs to discover edge cases you didn't think of.

| Language | Library | Example |
|----------|---------|---------|
| **TypeScript** | fast-check | `fc.assert(fc.property(fc.array(fc.integer()), (arr) => sort(arr).length === arr.length))` |
| **Python** | Hypothesis | `@given(st.lists(st.integers())) def test_sort_preserves_length(xs): assert len(sorted(xs)) == len(xs)` |
| **Java** | jqwik | `@Property void sortPreservesLength(@ForAll List<Integer> list) { assertEquals(list.size(), sort(list).size()); }` |
| **Go** | rapid | `rapid.Check(t, func(t *rapid.T) { xs := rapid.SliceOf(rapid.Int()).Draw(t, "xs"); assert len(Sort(xs)) == len(xs) })` |
| **Rust** | proptest | `proptest! { fn sort_preserves_length(v: Vec<i32>) { assert_eq!(sort(&v).len(), v.len()); } }` |
| **Haskell** | QuickCheck | `prop_sort_length xs = length (sort xs) == length xs` |

Use property-based testing for:
- Serialization roundtrips (`decode(encode(x)) == x`)
- Sorting invariants (length preserved, elements preserved, ordered)
- Mathematical properties (commutativity, associativity, idempotency)
- Parser/formatter pairs
- State machine testing (model-based testing)

## Mutation Testing

Measure test quality by introducing small code changes (mutants) and checking if tests catch them.

| Language | Tool | Command |
|----------|------|---------|
| **TypeScript/JavaScript** | Stryker | `npx stryker run` |
| **Python** | mutmut | `mutmut run --paths-to-mutate=src/` |
| **Java** | PIT (pitest) | `mvn org.pitest:pitest-maven:mutationCoverage` |
| **Rust** | cargo-mutants | `cargo mutants` |
| **C#/.NET** | Stryker.NET | `dotnet stryker` |

- **Mutation score**: Percentage of mutants killed by tests (target: > 80%)
- Surviving mutants reveal weak test assertions or missing test cases
- Run on critical business logic, not on all code (expensive)
- Integrate in CI as a quality gate on changed files

## Snapshot Testing

### When to Use
- Serialized output (JSON responses, HTML rendering, CLI output)
- Component rendering (React component trees)
- Configuration generation (Terraform plans, Kubernetes manifests)

### Anti-Patterns
- Snapshots of large objects — hard to review changes, easy to blindly update
- Snapshots of volatile data (timestamps, random IDs) — always failing
- Too many snapshots — maintenance burden, reviewers skip them
- Using snapshots as a substitute for meaningful assertions

### Best Practices
- Keep snapshots small and focused on the relevant output
- Use inline snapshots for small values: `expect(result).toMatchInlineSnapshot()`
- Review snapshot updates carefully in PRs — don't blindly `--update`
- Name snapshot files descriptively

## Property-Based Testing Libraries (Detailed)

| Language | Library | Generator Example | Shrinking |
|----------|---------|-------------------|-----------|
| **TypeScript** | fast-check | `fc.string()`, `fc.integer()`, `fc.record()` | Automatic |
| **Python** | Hypothesis | `st.text()`, `st.integers()`, `st.builds(User)` | Automatic, database of examples |
| **Java** | jqwik | `@ForAll String s`, `@IntRange(min=0, max=100)` | Automatic |
| **Go** | rapid | `rapid.String()`, `rapid.IntRange(0, 100)` | Automatic |
| **Rust** | proptest | `proptest! { fn test(s in ".*") {} }` | Automatic |
| **Haskell** | QuickCheck | `arbitrary :: Gen a`, `choose (0, 100)` | Automatic |
| **Scala** | ScalaCheck | `Gen.alphaStr`, `Gen.choose(0, 100)` | Automatic |
