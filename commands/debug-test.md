# Debug Test

Analyze a failing test and help identify the root cause.

## Usage

- `/debug-test` - Debug the last failed test
- `/debug-test src/utils.test.ts` - Debug specific test file
- `/debug-test "should handle empty input"` - Debug test by name
- `/debug-test --rerun` - Re-run and analyze the failure

## Task

Parse from: {{RAW_PROMPT}}

### 1. Identify the Failing Test

**If test file/name provided:**
Find and read the test.

**If nothing provided:**
Look for recent test output:
```bash
# Check for common test result files
cat test-results.json 2>/dev/null || \
cat jest-results.json 2>/dev/null || \
cat .test-output 2>/dev/null
```

Or rerun tests to capture output:
```bash
npm test 2>&1 | tee /tmp/test-output.txt
```

### 2. Parse Test Failure

Extract from test output:
- **Test name:** Full describe/it path
- **File:** Test file location
- **Error message:** What failed
- **Expected vs Actual:** If assertion failure
- **Stack trace:** Where it failed

### 3. Read the Test Code

```bash
# Read the test file
Read the test file at the identified location
```

Understand:
- What is being tested
- Test setup (beforeEach, mocks, fixtures)
- The specific assertion that failed
- Any async operations

### 4. Read the Implementation

Find the code under test:
```bash
# From import statements in test
rg "^import.*from ['\"](\.\./)*" TEST_FILE
```

Read the implementation file(s).

### 5. Analyze the Failure

**Common failure patterns:**

| Symptom | Likely Cause |
|---------|--------------|
| `undefined is not a function` | Mock not set up correctly |
| `Expected X but received undefined` | Async not awaited, wrong return |
| `Timeout` | Unresolved promise, infinite loop |
| `Cannot read property of null` | Setup/fixture issue |
| `toEqual` fails with same-looking values | Reference equality, Date objects, undefined vs missing |
| Works alone, fails in suite | Shared state, test pollution |
| Flaky (sometimes passes) | Race condition, time-dependent |

**Analysis approach:**
1. Compare expected vs actual values carefully
2. Check if mocks return what the code expects
3. Look for async issues (missing await)
4. Check test isolation (shared state)
5. Verify fixtures/setup match what code needs

### 6. Provide Diagnosis

```markdown
## Test Failure Analysis

### Test
**File:** `src/utils/format.test.ts`
**Name:** `formatCurrency › should handle negative numbers`

### Error
```
Expected: "-$10.00"
Received: "$-10.00"
```

### Root Cause

The `formatCurrency` function places the negative sign after the currency symbol
instead of before it.

**Implementation:** `src/utils/format.ts:23`
```typescript
function formatCurrency(amount: number): string {
  const formatted = Math.abs(amount).toFixed(2)
  const sign = amount < 0 ? '-' : ''
  return `$${sign}${formatted}`  // ← Bug: sign is after $
}
```

**The fix:**
```typescript
return `${sign}$${formatted}`  // ← sign should be before $
```

### Why This Happened

The implementation handles the negative sign separately from the number formatting,
but places it in the wrong position relative to the currency symbol.

### Suggested Fix

```diff
// src/utils/format.ts:23
- return `$${sign}${formatted}`
+ return `${sign}$${formatted}`
```

### Additional Tests to Consider

The current test suite might not cover:
- Zero values: `formatCurrency(0)`
- Very large numbers: `formatCurrency(1000000)`
- Floating point edge cases: `formatCurrency(0.1 + 0.2)`
```

### 7. For Complex Failures

If the root cause isn't obvious:

**Add diagnostic logging:**
```typescript
// Suggest adding to the test temporarily
console.log('Input:', input)
console.log('Mock returns:', mockFn.mock.results)
console.log('Actual output:', result)
```

**Isolate the test:**
```bash
npm test -- --testNamePattern="should handle negative" --verbose
```

**Check for test pollution:**
```bash
# Run test alone vs in suite
npm test -- src/utils/format.test.ts
npm test -- --runInBand  # Sequential execution
```

### 8. Flaky Test Analysis

If test is flaky (intermittent failures):

```markdown
## Flaky Test Analysis

### Symptoms
- Passes locally, fails in CI
- Passes when run alone, fails in suite
- Fails randomly ~20% of the time

### Likely Causes

1. **Timing/Race Condition**
   - Test doesn't wait for async operation
   - Fix: Add proper await, use `waitFor`, increase timeout

2. **Shared State**
   - Previous test modifies global/module state
   - Fix: Reset state in `beforeEach`, use `jest.isolateModules`

3. **Time-Dependent**
   - Test uses `Date.now()` or similar
   - Fix: Mock time with `jest.useFakeTimers()`

4. **External Dependencies**
   - Network calls, file system, database
   - Fix: Mock external dependencies

### Investigation Commands

```bash
# Run multiple times to reproduce
for i in {1..10}; do npm test -- --testNamePattern="flaky test"; done

# Run with different seed
npm test -- --randomize

# Run sequentially
npm test -- --runInBand
```
```

## Quality Checklist

- [ ] Failing test correctly identified
- [ ] Test code and implementation both read
- [ ] Root cause clearly explained
- [ ] Fix is specific and actionable
- [ ] Explanation helps prevent similar bugs
- [ ] Flaky tests get special analysis
