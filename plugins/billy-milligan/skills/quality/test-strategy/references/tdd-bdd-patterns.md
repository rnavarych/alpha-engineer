# TDD Patterns

## When to load
Load when explaining the TDD workflow, walking through red-green-refactor, setting test naming
conventions, or helping a team adopt test-first development.

## TDD: Red-Green-Refactor

```
RED   → Write a failing test for the desired behavior
GREEN → Write the minimum code to make it pass (no cleanup yet)
REFACTOR → Clean up code while keeping tests green
```

The cycle takes 2–10 minutes. If it takes longer, the scope is too large — split the work.

### TDD example: payment processing

```typescript
// STEP 1: RED — write the test first, no implementation exists yet
describe('PaymentService.charge', () => {
  it('should return successful charge result for valid card', async () => {
    const service = new PaymentService(mockGateway);
    const result = await service.charge({
      amount: 5000,  // $50.00 in cents
      currency: 'USD',
      cardToken: 'tok_valid',
    });

    expect(result.success).toBe(true);
    expect(result.chargeId).toBeDefined();
    expect(result.amount).toBe(5000);
  });
});
// Test fails: PaymentService doesn't exist yet. That's correct.

// STEP 2: GREEN — minimum implementation
class PaymentService {
  constructor(private gateway: PaymentGateway) {}

  async charge(params: ChargeParams): Promise<ChargeResult> {
    const response = await this.gateway.charge(params);
    return {
      success: response.status === 'succeeded',
      chargeId: response.id,
      amount: params.amount,
    };
  }
}
// Test passes. Now refactor if needed.

// STEP 3: REFACTOR — clean up, add error handling, extract constants
class PaymentService {
  constructor(private readonly gateway: PaymentGateway) {}

  async charge(params: ChargeParams): Promise<ChargeResult> {
    this.validateAmount(params.amount);
    const response = await this.gateway.charge(params);
    return this.mapGatewayResponse(response, params.amount);
  }

  private validateAmount(amount: number): void {
    if (amount <= 0) throw new InvalidAmountError(amount);
    if (amount > MAX_CHARGE_AMOUNT) throw new AmountExceedsLimitError(amount);
  }

  private mapGatewayResponse(response: GatewayResponse, amount: number): ChargeResult {
    return {
      success: response.status === 'succeeded',
      chargeId: response.id,
      amount,
    };
  }
}
// Tests still pass after refactor.
```

### TDD benefits beyond test coverage
- Forces you to think about the interface before implementation
- Prevents over-engineering: write only what makes the test pass
- Immediate feedback on design quality: if writing the test is hard, the API is wrong
- Built-in regression protection from the first line of real code

### When TDD is difficult (and what to do)
```
Difficult case                    | Adaptation
----------------------------------|--------------------------------------------
Exploring unfamiliar API/library  | Spike first (untested), then TDD real code
Pure UI/visual work               | Write unit tests for logic, skip visual assertions
Infrastructure glue code          | Integration test after the fact is acceptable
Performance-critical hot paths    | Write test first, then optimize while keeping green
```

## Test Naming Conventions

### Pattern: `should [result] when [condition]`

```typescript
// Good — reads like a specification
it('should reject payment when card is expired')
it('should send welcome email when user registers with valid email')
it('should return 404 when order does not exist')
it('should not allow two users to claim the same promo code simultaneously')
it('should calculate 10% discount when user has premium membership')

// Bad — describes implementation, not behavior
it('should call chargeCard')
it('tests the payment function')
it('paymentService works')
it('error case')
```

### Alternative pattern: `[action] given [condition]`

```typescript
it('returns empty array given no orders exist')
it('throws InsufficientFundsError given balance below charge amount')
it('sends notification given user has email alerts enabled')
```

### describe grouping structure

```typescript
describe('OrderService', () => {           // Class/module
  describe('createOrder', () => {          // Method/function
    describe('with valid input', () => {   // Happy path group
      it('should create order with correct total')
      it('should reserve inventory for each item')
      it('should send confirmation email')
    })

    describe('with invalid input', () => { // Error group
      it('should throw ValidationError when items list is empty')
      it('should throw UserNotFoundError when userId does not exist')
      it('should throw InsufficientStockError when any item is out of stock')
    })
  })
})
```

## Quick reference

```
TDD cycle         : RED (write test) → GREEN (min code) → REFACTOR (clean up)
Cycle time        : 2–10 minutes per cycle. Longer = scope too large.
Naming pattern    : 'should [result] when [condition]'
describe grouping : Class → Method → Condition → it()
TDD design signal : Hard to write test = wrong design, not wrong test
BDD/Gherkin       : see bdd-gherkin.md
```
