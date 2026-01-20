---
description: Find and organize TODO/FIXME/HACK annotations in your codebase
---

# Find TODOs

Find and organize all TODO, FIXME, HACK, and other code annotations in your codebase.

## Usage

- `/find-todos` - Find all TODOs in codebase
- `/find-todos --type=fixme` - Only FIXME comments
- `/find-todos --author=andy` - Filter by git blame author
- `/find-todos --stale=90` - Only TODOs older than 90 days
- `/find-todos src/` - Search specific directory

## Task

Parse options from: {{RAW_PROMPT}}

### 1. Search for Annotations

Find common code annotations:

```bash
# All annotation types
rg -n "(TODO|FIXME|HACK|XXX|BUG|OPTIMIZE|REVIEW|NOTE)(\(.*?\))?:?\s*" \
  --type-not=json --type-not=lock \
  -g "!node_modules" -g "!vendor" -g "!dist" -g "!build"
```

**Annotation types to find:**
| Type | Meaning | Priority |
|------|---------|----------|
| `FIXME` | Broken, needs immediate fix | 🔴 High |
| `BUG` | Known bug | 🔴 High |
| `HACK` | Workaround, technical debt | 🟡 Medium |
| `TODO` | Planned work | 🟡 Medium |
| `XXX` | Dangerous/problematic code | 🟡 Medium |
| `OPTIMIZE` | Performance improvement needed | 🟢 Low |
| `REVIEW` | Needs code review | 🟢 Low |
| `NOTE` | Informational | ⚪ Info |

### 2. Parse Each Match

Extract from each TODO:
- **Type**: TODO, FIXME, etc.
- **Author** (if present): `TODO(andy):` → andy
- **Text**: The actual todo content
- **File**: Path to file
- **Line**: Line number
- **Context**: Surrounding code (2-3 lines)

### 3. Enrich with Git Data

For each TODO, get age and author via git:

```bash
# Get blame for specific line
git blame -L LINE,LINE --porcelain FILE | head -20
```

Extract:
- **Commit date**: When was this line added
- **Author**: Who added it (if not in TODO itself)
- **Age**: Days since added

### 4. Filter Results

Apply filters:
- `--type=X`: Only show that type
- `--author=X`: Only show TODOs by that author (git blame)
- `--stale=N`: Only show TODOs older than N days
- Path argument: Only search in that directory

### 5. Generate Report

```markdown
## TODO Report

**Scanned:** 234 files
**Found:** 47 annotations

---

### 🔴 High Priority (FIXME/BUG): 5

| File | Line | Age | Author | Description |
|------|------|-----|--------|-------------|
| `src/auth.ts` | 45 | 180d | andy | FIXME: Race condition in token refresh |
| `src/api.ts` | 123 | 90d | sarah | BUG: Doesn't handle pagination |

<details>
<summary>View context</summary>

**src/auth.ts:45** (180 days old)
```typescript
// FIXME: Race condition in token refresh
// Multiple requests can trigger simultaneous refreshes
const token = await refreshToken()
```
</details>

---

### 🟡 Medium Priority (TODO/HACK/XXX): 28

#### By Category

**Technical Debt (HACK):** 8
| File | Line | Age | Description |
|------|------|-----|-------------|
| `src/utils.ts` | 89 | 365d | HACK: Workaround for Safari bug |

**Planned Work (TODO):** 18
| File | Line | Age | Description |
|------|------|-----|-------------|
| `src/components/Modal.tsx` | 12 | 30d | TODO: Add keyboard navigation |

**Problematic Code (XXX):** 2
| File | Line | Age | Description |
|------|------|-----|-------------|
| `src/legacy/parser.ts` | 456 | 500d | XXX: This will break for Unicode |

---

### 🟢 Low Priority (OPTIMIZE/REVIEW): 8

| Type | Count | Oldest |
|------|-------|--------|
| OPTIMIZE | 5 | 120 days |
| REVIEW | 3 | 45 days |

---

### ⚪ Notes: 6

Informational notes, no action needed.

---

### 📊 Statistics

**By Author:**
| Author | Count | Oldest |
|--------|-------|--------|
| andy | 23 | 365d |
| sarah | 15 | 180d |
| Unknown | 9 | 500d |

**By Age:**
| Age | Count |
|-----|-------|
| < 30 days | 8 |
| 30-90 days | 12 |
| 90-180 days | 15 |
| > 180 days | 12 |

**By Directory:**
| Directory | Count |
|-----------|-------|
| src/components | 18 |
| src/utils | 12 |
| src/legacy | 9 |
| tests | 8 |

---

### 🧹 Cleanup Suggestions

1. **Ancient TODOs (>1 year):** 5 items
   - Consider: Are these still relevant? Delete or do them.

2. **Orphaned FIXMEs:** 2 items by authors no longer on team
   - `src/legacy/parser.ts:456` - Unknown author

3. **Vague TODOs:** 4 items lack context
   - `TODO: fix this` - What needs fixing?
```

## Annotation Best Practices (for output)

When reporting, note if TODOs follow good practices:

**Good TODO:**
```typescript
// TODO(andy): Add rate limiting before v2 launch
// See: https://github.com/org/repo/issues/123
```

**Bad TODO:**
```typescript
// TODO: fix
```

Flag vague TODOs in the report.

## Quality Checklist

- [ ] All annotation types searched
- [ ] Git blame data enriches results
- [ ] Results grouped by priority
- [ ] Stale TODOs highlighted
- [ ] Vague TODOs flagged
- [ ] Statistics provide actionable insights
- [ ] Output is scannable (tables, not walls of text)
