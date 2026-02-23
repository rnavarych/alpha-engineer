# API Compatibility

## When to load
Load when evaluating breaking vs non-breaking API changes, versioning contracts.

## Breaking vs Non-Breaking Changes

```
Non-breaking (safe to deploy):
  ✅ Adding new optional field to response
  ✅ Adding new endpoint
  ✅ Adding new optional query parameter
  ✅ Adding new enum value (if consumer ignores unknown)
  ✅ Widening accepted input types
  ✅ Relaxing validation (accepting more)

Breaking (requires consumer update):
  ❌ Removing or renaming response field
  ❌ Removing endpoint
  ❌ Changing field type (string → number)
  ❌ Adding required request field
  ❌ Tightening validation (rejecting previously valid input)
  ❌ Changing error response format
  ❌ Changing HTTP status codes
  ❌ Removing enum values
```

## Robustness Principle (Postel's Law)

```
"Be conservative in what you send, be liberal in what you accept."

Consumer rules:
  - Ignore unknown fields in responses
  - Don't break on new enum values
  - Handle optional fields gracefully (default values)

Provider rules:
  - Never remove fields without deprecation period
  - Add new fields as optional
  - Version breaking changes
```

## Deprecation Strategy

```
1. Announce deprecation (docs + response header)
   Deprecation: true
   Sunset: Sat, 01 Jun 2025 00:00:00 GMT
   Link: <https://docs.api.com/migration>; rel="sunset"

2. Monitor usage (track which consumers still use deprecated field)

3. Grace period: minimum 3 months for external APIs

4. Remove after grace period expires and usage drops to 0
```

## Anti-patterns
- Removing response fields without checking consumers → instant breakage
- No deprecation headers → consumers surprised by removal
- Treating all changes as breaking → deployment velocity drops
- Version-per-change → too many versions to maintain

## Quick reference
```
Safe: add optional fields, add endpoints, relax validation
Breaking: remove fields, change types, add required fields
Deprecation: 3-month minimum, Sunset header, monitor usage
Consumer: ignore unknown, handle optional, don't depend on order
Provider: only add, never remove without deprecation cycle
Contract tests: catch breaking changes before deployment
```
