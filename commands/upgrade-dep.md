---
description: Upgrade a dependency and fix breaking changes
---

# Upgrade Dependency

Upgrade a specific dependency and fix breaking changes.

## Usage

- `/upgrade-dep lodash` - Upgrade to latest
- `/upgrade-dep react@18` - Upgrade to specific version
- `/upgrade-dep typescript --dry-run` - Show what would change
- `/upgrade-dep axios --breaking` - Show breaking changes first

## Task

Parse from: {{RAW_PROMPT}}

**Package:** First argument (required)
**Target version:** After `@` or `latest`
**Dry run:** `--dry-run` flag
**Breaking changes only:** `--breaking` flag

### 1. Analyze Current State

```bash
# Current version
npm list PACKAGE --depth=0

# What depends on this package
npm explain PACKAGE

# Current lockfile version
grep -A 2 '"PACKAGE"' package-lock.json | head -5
```

### 2. Research the Upgrade

**Get version info:**
```bash
npm view PACKAGE versions --json | tail -20
npm view PACKAGE time --json | tail -10
```

**Changelog/breaking changes:**
- Check `CHANGELOG.md` in package repo
- Check GitHub releases
- Check migration guides

If upgrading major versions, summarize breaking changes:

```markdown
### Breaking Changes: lodash 4.x → 5.x

1. **Removed methods:** `_.pluck` (use `_.map`), `_.where` (use `_.filter`)
2. **Changed behavior:** `_.merge` no longer merges arrays by index
3. **Dropped support:** Node.js < 14
```

### 3. Perform Upgrade (unless --dry-run)

```bash
npm install PACKAGE@VERSION
```

### 4. Find Affected Code

Search for usage patterns that might break:

```bash
# Direct imports
rg "from ['\"]PACKAGE" --type ts --type js

# Specific imports (if breaking change involves removed exports)
rg "import.*{.*REMOVED_EXPORT.*}.*from ['\"]PACKAGE" --type ts --type js

# Usage patterns
rg "PACKAGE\." --type ts --type js
```

### 5. Fix Breaking Changes

For each breaking change, find and fix affected code:

**Example: Method renamed**
```typescript
// Before
import { pluck } from 'lodash'
const names = pluck(users, 'name')

// After
import { map } from 'lodash'
const names = map(users, 'name')
```

Use the Edit tool to apply fixes across the codebase.

### 6. Verify

```bash
# Type check
npm run typecheck 2>&1 || npx tsc --noEmit 2>&1

# Run tests
npm test 2>&1 | head -50

# Build
npm run build 2>&1 | head -50
```

### 7. Generate Report

```markdown
## Upgrade Report: lodash 4.17.21 → 5.0.0

### Summary
- **Package:** lodash
- **Previous:** 4.17.21
- **New:** 5.0.0
- **Breaking changes:** 3 found, 3 fixed

### Breaking Changes Applied

#### 1. `_.pluck` removed
**Files affected:** 4
**Fix:** Replaced with `_.map`

| File | Line | Change |
|------|------|--------|
| `src/utils/format.ts` | 23 | `pluck(` → `map(` |
| `src/api/users.ts` | 45 | `pluck(` → `map(` |

#### 2. `_.where` removed
**Files affected:** 2
**Fix:** Replaced with `_.filter`

### Verification

- ✅ TypeScript compilation: passed
- ✅ Tests: 142 passed, 0 failed
- ✅ Build: successful

### Manual Review Needed

These usages couldn't be automatically fixed:

| File | Line | Issue |
|------|------|-------|
| `src/legacy/parser.ts` | 89 | Complex `_.merge` usage, verify behavior |

### Rollback

If issues arise:
```bash
git checkout package.json package-lock.json
npm install
```
```

## Dry Run Output

If `--dry-run`:

```markdown
## Upgrade Preview: lodash 4.17.21 → 5.0.0

### Breaking Changes

1. **`_.pluck` removed** (4 usages found)
   - `src/utils/format.ts:23`
   - `src/api/users.ts:45`
   - ...

2. **`_.where` removed** (2 usages found)
   - ...

### Risk Assessment

**Risk level:** Medium
- 6 code locations need changes
- 1 complex usage needs manual review
- Tests should catch regressions

### Proceed?

Run `/upgrade-dep lodash@5` to perform the upgrade.
```

## Common Packages with Migration Guides

| Package | Guide |
|---------|-------|
| react | reactjs.org/blog (version announcements) |
| typescript | typescriptlang.org/docs/handbook/release-notes |
| webpack | webpack.js.org/migrate |
| jest | jestjs.io/blog (release posts) |
| eslint | eslint.org/docs/user-guide/migrating-to-X |

## Quality Checklist

- [ ] Current usage fully analyzed
- [ ] Breaking changes identified
- [ ] All affected files found
- [ ] Fixes applied correctly
- [ ] Types still compile
- [ ] Tests still pass
- [ ] Complex cases flagged for review
- [ ] Rollback instructions provided
