# Find Dead Code

Identify unused exports, unreferenced files, and orphaned code in your codebase.

## Usage

- `/find-dead-code` - Scan entire codebase
- `/find-dead-code src/utils` - Scan specific directory
- `/find-dead-code --type=exports` - Only find unused exports
- `/find-dead-code --type=files` - Only find orphaned files
- `/find-dead-code --fix` - Also remove the dead code (with confirmation)

## Task

Parse path and options from: {{RAW_PROMPT}}

**Target path:** First non-flag argument, or `.` if not provided
**Type filter:** `--type=exports|files|all` (default: all)
**Fix mode:** `--fix` flag present

### 1. Detect Project Type

Identify the project type to determine file patterns:
- **TypeScript/JavaScript**: Check for `tsconfig.json`, `package.json`
- **Python**: Check for `pyproject.toml`, `setup.py`, `requirements.txt`
- **Ruby**: Check for `Gemfile`
- **Go**: Check for `go.mod`

### 2. Find Unused Exports (TypeScript/JavaScript)

For each file with exports:

```bash
# Find all export statements
rg "^export (const|function|class|type|interface|enum|default)" --type ts --type js -l

# For each exported symbol, check if it's imported anywhere
rg "import.*{.*SYMBOL.*}" --type ts --type js
rg "import SYMBOL" --type ts --type js
```

**Exclude from dead code detection:**
- Entry points (`index.ts`, `main.ts`, files in `bin/`)
- Test files (`*.test.ts`, `*.spec.ts`, `__tests__/`)
- Type definition files that are published (`*.d.ts` in `dist/`)
- Exports marked with `// @public` or similar annotations
- Files listed in `package.json` exports/main/bin

**Check for dynamic imports:**
```bash
# These might use the export dynamically
rg "import\(" --type ts --type js
rg "require\(" --type ts --type js
```

### 3. Find Orphaned Files

Files that are never imported or referenced:

```bash
# Get all source files
fd -e ts -e tsx -e js -e jsx

# For each file, check if it's imported anywhere
rg "from ['\"].*FILENAME" --type ts --type js
rg "require\(['\"].*FILENAME" --type ts --type js
```

**Exclude:**
- Entry points and configs
- Test files (they import, aren't imported)
- Type declarations
- Scripts in `scripts/`, `bin/`

### 4. Language-Specific Checks

**Python:**
```bash
# Find defined but unused functions/classes
rg "^def |^class " --type py -l
# Check for imports
rg "from .* import SYMBOL|import .*SYMBOL" --type py
```

**Ruby:**
```bash
# Find module/class definitions
rg "^(module|class) " --type ruby -l
# Check for requires/includes
rg "require.*FILENAME|include SYMBOL" --type ruby
```

### 5. Report Results

Group findings by category:

```markdown
## Dead Code Report

**Scanned:** [N] files in [path]
**Found:** [N] potentially unused items

### Unused Exports

| File | Export | Type | Confidence |
|------|--------|------|------------|
| `src/utils/format.ts` | `formatCurrency` | function | High |
| `src/utils/format.ts` | `formatDate` | function | Medium* |

*Medium confidence: found in dynamic import patterns

### Orphaned Files

| File | Last Modified | Lines |
|------|---------------|-------|
| `src/old/legacy.ts` | 2023-04-15 | 245 |
| `src/utils/deprecated.ts` | 2023-08-20 | 89 |

### Possibly Dead (Manual Review)

These are referenced only in tests or comments:
- `src/internal/helper.ts` - only in test files
- `src/types/legacy.ts` - only in JSDoc comments

### Safe to Ignore

Entry points and intentionally public exports:
- `src/index.ts` - package entry point
- `src/bin/cli.ts` - CLI entry point
```

### 6. Fix Mode (if --fix)

If `--fix` is specified:

1. Show the report first
2. Ask for confirmation: "Remove [N] unused items? (y/n)"
3. For each item:
   - **Unused exports:** Remove the export keyword or entire declaration
   - **Orphaned files:** Delete the file
4. Run tests after removal to verify nothing broke

```markdown
## Removed

- ✅ Deleted `src/old/legacy.ts`
- ✅ Removed export `formatCurrency` from `src/utils/format.ts`
- ❌ Kept `formatDate` - tests failed after removal
```

## Confidence Levels

**High:** No references found anywhere in codebase
**Medium:** Only found in:
- Dynamic imports (might be used at runtime)
- String literals (might be used for reflection)
- Comments or documentation

**Low:** Found in:
- Test files only
- Config files
- Build scripts

## Edge Cases

**Re-exports:** A file might re-export from another:
```typescript
// src/index.ts
export { helper } from './utils'  // helper is "used"
```

**Barrel files:** `index.ts` files that aggregate exports are not dead even if the index itself isn't imported.

**Side effects:** Some imports are for side effects:
```typescript
import './polyfills'  // No exports used, but file is needed
```

**Framework magic:** Some frameworks auto-discover files:
- Next.js `pages/` directory
- Jest `__tests__/` directory
- Storybook `*.stories.tsx`

## Quality Checklist

- [ ] Entry points correctly identified
- [ ] Test files excluded from "dead" classification
- [ ] Framework-specific patterns respected
- [ ] Dynamic imports noted as medium confidence
- [ ] Re-exports properly traced
- [ ] Report clearly distinguishes confidence levels
