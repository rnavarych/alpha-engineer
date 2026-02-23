# API Test Coverage Checklist

## When to load
When auditing coverage of an existing API test suite; when defining what scenarios must be covered for a new endpoint; when reviewing test completeness against REST/GraphQL spec.

## HTTP Scenario Coverage

- **Happy path**: Valid request returns 2xx with expected body.
- **Validation**: Invalid input returns 400 with descriptive errors.
- **Authentication**: Missing/expired tokens return 401.
- **Authorization**: Forbidden actions return 403.
- **Not found**: Non-existent resources return 404.
- **Idempotency**: Repeated requests produce same result.
- **Pagination**: Page size, offset, total count, next/previous links.
- **Rate limiting**: 429 when limits exceeded.

## GraphQL-Specific Coverage

- Query with valid variables returns expected shape.
- Query with missing required variable returns validation error.
- Mutation returns expected payload and persists the change.
- Unauthorized mutation returns permission error in `errors` array.
- Subscription delivers events to connected clients.
- Introspection is disabled in production (if required by security policy).

## Error Response Quality

- Error messages describe the problem in human-readable terms.
- Validation errors identify which field failed and why.
- No stack traces, internal paths, or database error details exposed.
- RFC 7807 Problem Details format where applicable: `type`, `title`, `status`, `detail`.

## Edge Cases Worth Testing

- Payload at max allowed size.
- Special characters in string fields (Unicode, emoji, null bytes).
- Concurrent identical requests (race conditions on create endpoints).
- Requests with extra unknown fields (should be ignored, not 400).
- Content-Type mismatch (JSON endpoint receiving form data).
