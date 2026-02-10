---
description: Upgrade a dependency and fix breaking changes
memory: local
---

Upgrade a dependency and fix all breaking changes across the codebase.

## Process

Parse from: {{RAW_PROMPT}} — expects `package[@version]`, supports `--dry-run` and `--breaking`.

1. **Audit current state**: Check installed version, what depends on it, and all import/usage sites in the codebase
2. **Research breaking changes**: Check changelogs, GitHub releases, and migration guides for the target version. For major bumps, summarize breaking changes before proceeding
3. **Upgrade** (unless `--dry-run`): Install the new version, then find and fix every affected import and usage pattern
4. **Verify**: Run type checking, tests, and build. Flag anything that needs manual review

## Output

Report: package, old version, new version, breaking changes found/fixed, files modified with specific changes, verification results (types/tests/build), and anything flagged for manual review.

If `--dry-run`: report breaking changes and affected code locations with a risk assessment, but don't modify anything.

Remember the project's package manager, test/build commands, and any quirks you discover in your memory.
