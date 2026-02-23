# Unit Testing Patterns

## When to load
Load when writing unit tests, choosing assertion patterns, or implementing TDD/BDD workflows.

## Unit Testing Principles
- Test behavior, not implementation — if refactoring breaks tests without changing behavior, tests are too coupled
- One assertion per logical concept (multiple asserts are fine if they verify one behavior)
- Follow AAA pattern: Arrange, Act, Assert (or Given/When/Then for BDD)
- Use descriptive test names: `should_return_error_when_email_is_invalid` or `test_order_total_includes_tax`
- Keep tests independent — no shared mutable state, no test ordering dependencies
- Aim for <100ms per unit test, <10ms is ideal
- Test edge cases explicitly: null/nil, empty collections, boundary values, negative numbers, max values

## Unit Testing by Language

### Jest / Vitest (TypeScript/JavaScript)
```typescript
// Vitest / Jest — AAA pattern
describe('OrderService', () => {
  it('should calculate total with tax', () => {
    // Arrange
    const items = [{ price: 10, quantity: 2 }, { price: 5, quantity: 1 }];
    const taxRate = 0.08;

    // Act
    const total = calculateOrderTotal(items, taxRate);

    // Assert
    expect(total).toBe(27.0); // (10*2 + 5*1) * 1.08
  });

  it('should throw for empty items', () => {
    expect(() => calculateOrderTotal([], 0.08)).toThrow('Items cannot be empty');
  });
});
```

### pytest (Python)
```python
# pytest — fixtures and parametrize
import pytest
from order_service import calculate_order_total

@pytest.fixture
def sample_items():
    return [{"price": 10, "quantity": 2}, {"price": 5, "quantity": 1}]

def test_order_total_with_tax(sample_items):
    assert calculate_order_total(sample_items, tax_rate=0.08) == 27.0

@pytest.mark.parametrize("items,tax,expected", [
    ([{"price": 100, "quantity": 1}], 0.0, 100.0),
    ([{"price": 100, "quantity": 1}], 0.1, 110.0),
    ([], 0.08, pytest.raises(ValueError)),
])
def test_order_total_parametrized(items, tax, expected):
    if isinstance(expected, type) or hasattr(expected, '__enter__'):
        with expected:
            calculate_order_total(items, tax)
    else:
        assert calculate_order_total(items, tax) == expected
```

### JUnit 5 (Java)
```java
// JUnit 5 — nested tests and display names
@DisplayName("OrderService")
class OrderServiceTest {
    @Nested
    @DisplayName("calculateTotal")
    class CalculateTotal {
        @Test
        @DisplayName("should include tax in total")
        void shouldIncludeTax() {
            var items = List.of(new Item(10, 2), new Item(5, 1));
            var total = OrderService.calculateTotal(items, 0.08);
            assertThat(total).isCloseTo(27.0, within(0.01));
        }

        @ParameterizedTest
        @CsvSource({"0.0, 25.0", "0.08, 27.0", "0.2, 30.0"})
        void shouldApplyDifferentTaxRates(double taxRate, double expected) {
            var items = List.of(new Item(10, 2), new Item(5, 1));
            assertThat(OrderService.calculateTotal(items, taxRate)).isCloseTo(expected, within(0.01));
        }
    }
}
```

### testing (Go)
```go
// Go — table-driven tests
func TestCalculateOrderTotal(t *testing.T) {
    tests := []struct {
        name    string
        items   []Item
        taxRate float64
        want    float64
        wantErr bool
    }{
        {"with tax", []Item{{10, 2}, {5, 1}}, 0.08, 27.0, false},
        {"no tax", []Item{{10, 2}, {5, 1}}, 0.0, 25.0, false},
        {"empty items", nil, 0.08, 0, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateOrderTotal(tt.items, tt.taxRate)
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.InDelta(t, tt.want, got, 0.01)
        })
    }
}
```

### xUnit (.NET)
```csharp
// xUnit — Theory with InlineData
public class OrderServiceTests
{
    [Theory]
    [InlineData(0.0, 25.0)]
    [InlineData(0.08, 27.0)]
    [InlineData(0.2, 30.0)]
    public void CalculateTotal_WithTaxRate_ReturnsCorrectTotal(decimal taxRate, decimal expected)
    {
        var items = new[] { new Item(10, 2), new Item(5, 1) };
        var result = OrderService.CalculateTotal(items, taxRate);
        Assert.Equal(expected, result, precision: 2);
    }
}
```

## TDD / BDD Workflows

### TDD (Test-Driven Development)
1. **Red**: Write a failing test that describes the desired behavior
2. **Green**: Write the minimum code to make the test pass
3. **Refactor**: Improve the code while keeping tests green

Best for: algorithm design, utility functions, business logic, bug fixes (write test that reproduces bug first).

### BDD (Behavior-Driven Development)
```gherkin
Feature: User Registration
  Scenario: Successful registration
    Given the user is on the registration page
    When they submit valid registration details
    Then they should see a welcome message
    And they should receive a confirmation email

  Scenario: Registration with existing email
    Given a user with email "alice@example.com" already exists
    When a new user tries to register with "alice@example.com"
    Then they should see an error "Email already registered"
```

Tools: Cucumber (multi-language), behave (Python), Godog (Go), SpecFlow (.NET)
