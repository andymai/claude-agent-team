---
description: Run the project's local quality gate (fmt + lint + types + tests)
memory: local
---

Run the project's local quality gate — the same checks pre-commit/pre-push hooks (and CI) would run. Auto-detect what to invoke; don't hardcode a tool.

## Process

Parse from: {{RAW_PROMPT}} — supports `--fast` (skip tests, fmt+lint+types only), `--scope=<path>` (limit to a subtree), `--fix` (auto-apply formatters/linters that support it).

### 1. Detect the gate

Check in this order. Use the first match:

1. **Project-defined recipe**
   - `justfile` with a `check` target → `just check`
   - `Makefile` with a `check` target → `make check`
   - `package.json` with a `validate` / `check` / `ci` script → `npm run <script>` (or `pnpm`/`yarn` if their lockfile exists)
   - `Cargo.toml` workspace with an `xtask` crate that has `check` → `cargo xtask check`

2. **Pre-commit/lefthook config** — if `.lefthook.yml` or `.pre-commit-config.yaml` exists, run it directly (`lefthook run pre-commit`, `pre-commit run --all-files`).

3. **Stack defaults** (only if nothing above matches):
   - Rust: `cargo fmt --all -- --check && cargo clippy --all-targets -- -D warnings && cargo test --workspace`
   - TypeScript/JS: detect package manager (lockfile), then `<pm> run typecheck && <pm> run lint && <pm> run test`
   - Python: `ruff check . && ruff format --check . && pytest` (or `pyright`/`mypy` if configured)
   - Go: `gofmt -l . && go vet ./... && go test ./...`

State which gate you detected and why before running.

### 2. Run in tiers (when possible)

Mirror your pinned repos' hook structure:

- **Tier 1 (parallel)**: format check + lint + type check. These don't share state, run them concurrently if the gate detection allows it.
- **Tier 2 (sequential)**: tests. Run after Tier 1 passes — failing fmt/lint is cheaper to fix first.

If `--fast`, stop after Tier 1.

### 3. On failure

Surface the *first* failure clearly, with the fix command if obvious:

- `cargo fmt --all` to fix fmt
- `cargo clippy --fix --allow-dirty` for safe clippy fixes
- `<pm> run lint:fix` / `<pm> run format` for JS
- `ruff check --fix .` for Python

If `--fix` is passed, attempt the auto-fixes and re-run the gate once.

If a tool isn't installed, suggest the install command — don't abort silently.

### 4. Report

Concise summary: which checks ran, which passed, which failed. If everything passed, one line is enough. If some failed, group output by check, not by file.

## Conventions

- Don't invent commands. If the project doesn't have a documented gate, say so and propose one rather than running an ad-hoc combination.
- The goal is parity with CI. If a check passes locally but CI uses a stricter flag (e.g. `--all-features`), surface that gap.
- Save the detected gate command in your memory so the next run skips detection.
