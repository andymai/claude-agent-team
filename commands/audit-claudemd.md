---
description: Audit or bootstrap the project's CLAUDE.md against observed conventions
memory: local
---

Audit the project's `CLAUDE.md` (or `AGENTS.md`) against the actual codebase, then propose or apply updates.

## Process

Parse from: {{RAW_PROMPT}} — supports `--apply` (write changes; default is propose-only), `--bootstrap` (no CLAUDE.md exists; create one from scratch), `--file=CLAUDE.md|AGENTS.md` (target a specific file), `--scope=<area>` (focus the audit on one section, e.g. `--scope=gotchas`).

Invoke the `documenter` agent with the audit task. Direct it to:

1. **Discover the codebase shape** — stack from manifests, lint configs for the style table, directory structure, primary abstraction (stores / crates / engines / slices), result/error conventions, project scripts.
2. **Scan recent fix-commit history** — `git log --grep='fix' --oneline -n 100` to surface recurring gotchas worth documenting as Critical Gotchas.
3. **Compare against the current CLAUDE.md** (if one exists) — section by section, mark each as `✓ accurate`, `⚠ partially stale`, `✗ contradicted by code`, or `+ missing-but-recommended`.
4. **Report findings as a structured list** before any writes happen, so you can sanity-check.
5. **Apply the diff** if `--apply` was passed, otherwise stop after the proposal.

## Bootstrap mode

When `--bootstrap` is set or no CLAUDE.md exists:

- Don't infer aspirational content. Only document what the codebase actually does.
- Default to the 8-section template documented in `documenter` agent.
- Keep total length under ~300 lines for the first pass — better to have a tight, accurate CLAUDE.md than a sprawling one that ages badly.

## Constraints

- Never overwrite without `--apply`. Always show the proposed diff first.
- Honor existing voice and structure — don't rewrite sections that are accurate just because the agent has a different style preference.
- Don't add sections the project clearly doesn't need (e.g., a "Stores" table for a project with no stores).

## After the audit

Print the verdict summary. If writes were applied, show the diff and confirm git status. If proposals only, output them in a format the user can quickly accept or reject section by section.
