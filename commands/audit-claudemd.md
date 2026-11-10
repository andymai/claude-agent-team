---
description: Audit or bootstrap the project's CLAUDE.md against observed conventions
---

Audit the project's `CLAUDE.md` (or `AGENTS.md`) against the actual codebase, then propose or apply updates.

CLAUDE.md is load-bearing for every Claude Code session in a repo. A good one lets agents act with confidence; a thin one forces them to discover conventions from scratch each time. A stale one is worse than a missing section, because it misleads.

## Process

Parse from: {{RAW_PROMPT}} — supports `--apply` (write changes; default is propose-only), `--bootstrap` (no CLAUDE.md exists; create one from scratch), `--file=CLAUDE.md|AGENTS.md` (target a specific file), `--scope=<area>` (focus the audit on one section, e.g. `--scope=gotchas`).

1. **Discover the codebase shape.** Derive every section from evidence, never from imagination:
   - **Stack**: read `package.json` / `Cargo.toml` / `pyproject.toml` for dependencies and versions. List the actual stack, not aspirational tooling.
   - **Code style** (Required / Prohibited table): pull from lint configs (`eslint.config.*`, `clippy.toml`, `rubocop.yml`, `ruff.toml`). These encode rules the project already enforces, so agents can tell automated rules from aspirational ones.
   - **Directory structure**: `tree -L 2 src/` or equivalent, with each top-level directory annotated. Skip generated and build directories.
   - **Core abstraction**: for a project with a clear unit (stores, slices, crates, engines), a table mapping each unit to its responsibility. Read the source to fill it.
   - **Result/error conventions**: `Result<T,E>`, custom error enums, or exception classes, with import paths and the user-facing display helper.
   - **Commands**: the actual `check`, `test`, `build`, and `format` invocations, from `package.json` scripts, `Makefile`, `justfile`, `.cargo/config.toml`, or CI workflows.
2. **Scan recent fix-commit history.** Run `git log --grep='fix' --oneline -n 100`. Recurring fix patterns ("coordinate origin", "ID stability", "init order") are Critical Gotchas. Especially flag invariants that the type system cannot enforce.
3. **Compare against the current CLAUDE.md** (if one exists), section by section. Mark each `✓ accurate`, `⚠ partially stale`, `✗ contradicted by code`, or `+ missing-but-recommended`, with the specific fix.
4. **Report findings as a structured list** before any writes happen, so the user can check them.
5. **Apply the diff** if `--apply` was passed, otherwise stop after the proposal.

## Sections that earn their place

1. One-paragraph project summary (what it is, why it exists).
2. Stack (terse, comma-separated).
3. Git and quality gates (protected branches, pre-commit hooks, required checks).
4. Code style (Required / Prohibited table).
5. Directory structure (annotated tree).
6. Core architecture (stores, modules, layers: whatever the project's primary abstraction is).
7. Critical gotchas (numbered list of invariants and footguns).
8. How to run, test, and build (one-line commands).

Push back on:

- Aspirational tooling that isn't actually wired up.
- Generic best practices that apply to any project ("write good tests", "use meaningful names"). They waste every agent's context window.
- Detailed API docs that belong in the code itself.
- Long onboarding narratives. Link to a separate ONBOARDING.md instead.

## Bootstrap mode

When `--bootstrap` is set or no CLAUDE.md exists:

- Don't infer aspirational content. Only document what the codebase actually does.
- Default to the 8 sections above.
- Keep total length under ~300 lines for the first pass — better to have a tight, accurate CLAUDE.md than a sprawling one that ages badly.

## Constraints

- Never overwrite without `--apply`. Always show the proposed diff first.
- Honor existing voice and structure — don't rewrite sections that are accurate just because you prefer a different style.
- Don't add sections the project clearly doesn't need (e.g., a "Stores" table for a project with no stores).

## After the audit

Print the verdict summary. If writes were applied, show the diff and confirm git status. If proposals only, output them in a format the user can quickly accept or reject section by section.
