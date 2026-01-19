# Explain Error

Decode error messages and stack traces in the context of your codebase.

## Usage

- `/explain-error` - Explain the last error (from terminal history or paste)
- `/explain-error <paste error here>` - Explain specific error
- `/explain-error --suggest-fix` - Also suggest how to fix it

## Task

Parse the error from: {{RAW_PROMPT}}

If no error provided, ask user to paste it.

### 1. Parse the Error

Extract key components:

**Error Type:**
- JavaScript: `TypeError`, `ReferenceError`, `SyntaxError`, etc.
- Python: `ValueError`, `KeyError`, `AttributeError`, etc.
- Ruby: `NoMethodError`, `ArgumentError`, etc.
- Go: panic messages, error returns
- Generic: HTTP status codes, database errors

**Error Message:**
The human-readable description.

**Stack Trace:**
- File paths
- Line numbers
- Function/method names
- Call sequence (most recent first or last)

**Context:**
- Environment (Node, browser, Python version)
- Framework (React, Rails, Django)
- Operation being performed

### 2. Locate in Codebase

For each file in the stack trace that exists locally:

```bash
# Check if file exists
test -f "path/to/file.ts" && echo "exists"
```

Read the relevant lines:
- The exact line mentioned
- 5-10 lines of surrounding context
- The function/method containing the error

### 3. Analyze Root Cause

**Common patterns:**

| Error Pattern | Likely Cause |
|---------------|--------------|
| `undefined is not a function` | Calling method on undefined value |
| `Cannot read property 'x' of null` | Null pointer, missing null check |
| `is not defined` | Typo, missing import, scope issue |
| `ENOENT` | File/directory doesn't exist |
| `ECONNREFUSED` | Service not running, wrong port |
| `404 Not Found` | Wrong URL, missing route |
| `500 Internal Server Error` | Server-side exception |
| `CORS` | Missing CORS headers, wrong origin |
| `out of memory` | Memory leak, large data |
| `maximum call stack` | Infinite recursion |
| `deadlock` | Circular lock dependency |
| `timeout` | Slow operation, network issue |

### 4. Explain in Plain English

Structure the explanation:

```markdown
## Error Explained

### What Happened
[1-2 sentences: plain English description of the error]

### Why It Happened
[Explanation of the root cause based on your code]

### Where It Happened
**File:** `src/services/api.ts:45`
**Function:** `fetchUserData()`
**Line:**
```typescript
const name = user.profile.name  // user.profile is undefined
```

### Call Stack (Simplified)
1. `handleSubmit()` in `src/components/Form.tsx:23`
2. `validateUser()` in `src/utils/validation.ts:67`
3. `fetchUserData()` in `src/services/api.ts:45` ← Error here

### The Problem
[Detailed explanation with code context]

The `user` object was returned from the API, but the `profile` field is `null`
when the user hasn't completed onboarding. The code assumes `profile` always exists.
```

### 5. Suggest Fix (if --suggest-fix)

```markdown
## Suggested Fix

### Option 1: Add Null Check (Quick Fix)
```typescript
// Before
const name = user.profile.name

// After
const name = user.profile?.name ?? 'Anonymous'
```

### Option 2: Validate API Response (Better)
```typescript
// Add validation when fetching user
const user = await fetchUser(id)
if (!user.profile) {
  throw new Error('User profile not loaded')
}
```

### Option 3: Fix at Source (Best)
Ensure the API always returns a profile object, even if empty:
```json
{ "profile": { "name": null, "avatar": null } }
```

### Recommendation
Option 2 is recommended - it fails fast with a clear error message rather than
silently using a fallback value.
```

### 6. Related Issues

If the error seems common:
- Check if similar errors exist in codebase (grep for error message)
- Note if this is a known issue pattern
- Link to relevant documentation if applicable

## Error-Specific Guidance

### JavaScript/TypeScript
- Check for async/await issues (missing await)
- Look for this binding problems
- Verify import paths

### React
- Check component lifecycle
- Look for state updates on unmounted components
- Verify hooks rules

### Node.js
- Check for unhandled promise rejections
- Verify file paths (relative vs absolute)
- Check environment variables

### Python
- Check indentation
- Verify virtual environment
- Look for circular imports

### Database
- Check connection strings
- Verify migrations are current
- Look for constraint violations

## Output Format

Keep explanations:
- **Concise**: Focus on what matters
- **Actionable**: Include specific fixes
- **Educational**: Explain the "why"
- **Contextual**: Reference the actual code, not generic advice

## Quality Checklist

- [ ] Error type correctly identified
- [ ] Root cause explained in plain English
- [ ] Relevant source code located and shown
- [ ] Stack trace simplified to relevant frames
- [ ] Fix suggestions are specific to this codebase
- [ ] No generic copy-paste advice
