# Anonymization, Synthetic Data, and Fixture Management

## When to load
When masking production data for test environments; when generating synthetic datasets; when deciding between factories and fixtures; when seeding random generators for reproducibility.

## Anonymization and Masking

| Field | Technique | Example |
|-------|-----------|---------|
| Email | Domain replacement | `user@co.com` → `user1@test.invalid` |
| Name | Faker replacement | `John Smith` → `Alice Johnson` |
| Phone | Format preservation | `+1-555-123-4567` → `+1-555-000-0001` |
| SSN/CC | Full replacement | Replace with test values or tokens |

- Anonymize in a separate pipeline. Never expose raw production data to test environments.
- Maintain referential integrity: the same source ID must always map to the same anonymized ID.
- Document the anonymization pipeline and the fields it covers. Treat the pipeline itself as production code.

## Synthetic Data Generation
- Generate data that statistically resembles production without using real records.
- Generate edge cases explicitly: Unicode names, max-length fields, special characters, null values.
- Seed the random generator for reproducibility: `faker.seed(12345)`.
- Include boundary values: minimum and maximum allowed lengths, zero quantities, negative amounts (where invalid).

## Fixture Management
- Use fixtures for data that must be exactly the same across all test runs (contract tests, snapshot tests).
- Keep fixtures small and focused — one fixture per scenario, not one giant shared file.
- Prefer factories over fixtures for most tests: factories generate fresh unique data; fixtures are static and can collide.
- Store fixtures in version control. Changes to fixtures are changes to test expectations — review them as such.
