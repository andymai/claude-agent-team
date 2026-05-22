---
description: Create a branch following <type>/<kebab-description> naming
memory: local
---

Create a new git branch following the `<type>/<kebab-case-description>` convention, where `<type>` matches the conventional-commit type the work will produce.

## Process

Parse from: {{RAW_PROMPT}} — supports `--type=TYPE`, `--from=<base>` (default: `main`), `--issue=N` (embed issue number as a leading segment), `<description>` (free text; will be kebab-cased).

### 1. Determine type

If `--type` is passed, use it. Otherwise infer from the user's request or recent context:

- `feat` — new user-facing feature or capability
- `fix` — bug fix
- `refactor` — same behavior, different shape
- `perf` — performance improvement
- `docs` — documentation only
- `test` — tests only
- `chore` — tooling, deps, repo hygiene
- `ci` / `build` — pipeline / build config
- `revert` — reverting a previous commit
- `style` — formatting only (rare)

If you can't infer the type with confidence, ask before creating the branch.

### 2. Kebab-case the description

- Lowercase
- Spaces → `-`
- Strip punctuation except `-`
- Cap at ~50 chars for the description portion
- No trailing `-`
- No `feat-feat-...` redundancy with the type prefix

If `--issue=N` was passed (or you detect a `#NNN` / `issue NNN` reference in the description), prepend the issue number as the first description segment: `<type>/<issue>-<rest-of-description>`. Strip the duplicate `#NNN` from the description portion so the issue number appears exactly once.

Examples (real ones from these repos):
- `docs/claudemd-version-qualifier`
- `refactor/rip-mag-data-only`
- `feat/sim-host-visualizer`
- `chore/prune-info-logs`
- `fix/i2c-100khz-py32`
- `fix/696-cross-triangle-collinear-collapse` (with `--issue=696`)
- `fix/1850-scoop-rim-fillet` (with `--issue=1850`)

### 3. Sanity checks

- Working tree clean? If not, list dirty paths and ask before switching base.
- Branch already exists locally or on origin? If yes, ask whether to check out the existing one instead.
- On the right base? Update first: `git fetch origin && git checkout <base> && git pull --ff-only`.

### 4. Create and switch

```bash
git checkout -b <type>/<kebab-description> <base>
```

Confirm with `git branch --show-current`.

### 5. Post-setup

Print the new branch name and a one-liner of what the user said they'd be working on, so it's visible at session start.

## Conventions

- One branch = one logical feature = one PR. If the description has multiple unrelated nouns, propose splitting into two branches.
- Branch type and the eventual commit type should match. If you make a `feat/` branch and your only commit is `chore: bump deps`, the branch name lied — rename or recommit.
