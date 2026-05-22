# AGENTS.md

A playbook for AI agents working on `claude-agent-team` itself. CLAUDE.md (when present) is shared human+agent guidance; this file is agent-specific.

## At a glance

- **What this repo is**: a curated bundle of Claude Code agent definitions (`agents/*.md`) and slash commands (`commands/*.md`), installed into `~/.claude/` via `scripts/install.sh`.
- **Distribution model**: agents and commands ship to `~/.claude/agents/` and `~/.claude/commands/` and run **across every project the user touches**. They must be portable.
- **The hard rule**: agents must not encode project-specific conventions. Read the local project's `CLAUDE.md`/`AGENTS.md` and follow *that*.

## The Generalization Rule

Every agent here is loaded by every Claude session for every repo. So:

- Don't hardcode language-specific rules. `unwrap()` is a Rust concept; `any` is TS-specific. Say "no panics in library code if the project bans them" — let the project's docs supply the specifics.
- Don't hardcode tool names. `pnpm`, `cargo`, `just` don't all exist everywhere. Say "the project's check command" and detect it.
- Don't hardcode paths. `src/core/store/` makes sense in gridfinity; nowhere else.
- Do encode **meta-patterns**: "find the project's error-handling convention before writing", "discover where tests live before placing one", "prefer property-based testing where the project already uses it."

When you upgrade an agent, ask: *would this rule make sense in a brand-new repo with a different stack?* If no, generalize it.

## Frontmatter Schema

### Agents (`agents/*.md`)

```yaml
---
name: <kebab-case>              # required, matches filename without .md
description: <one paragraph>    # required, used by Claude to decide when to invoke
tools: <comma-separated>        # required, see allowed tools below
disallowedTools: <list>         # optional, blocks specific tools (e.g., Write, Edit for read-only agents)
model: opus | sonnet | haiku    # required, see model selection below
memory: local                   # required, project-scoped memory (never `global`)
color: <ANSI color>             # required, see palette below
---
```

**Allowed tool names**: `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebSearch`, `WebFetch`. (Don't list tools the agent never uses — the description should make use of every listed tool.)

**Model selection**:
- `opus` — reasoning-heavy work: planning, architecture, debugging, security, review, research, gap-finding.
- `sonnet` — pattern-following work where speed matters: testing, optimization, documentation, context audits.
- `haiku` — short, deterministic transforms only (currently unused here).

**Color palette** (chosen for visual distinction in the agent picker):
- `green` / `brightGreen` — building (engineer, documenter)
- `red` / `brightRed` — finding problems (reviewer, debugger)
- `brightYellow` / `yellow` — testing/security (security, tester)
- `cyan` / `brightCyan` / `brightBlue` / `blue` — planning/research/architecture (optimizer, planner, architect, researcher)
- `magenta` / `brightMagenta` — gap-finding, review-responding (post-PR feedback work)
- `white` — auditing (context-auditor)

Avoid duplicating colors across agents that the user might invoke in the same workflow.

### Commands (`commands/*.md`)

```yaml
---
description: <one short line>    # required
memory: local                    # required
---
```

Commands receive the raw user prompt via `{{RAW_PROMPT}}`. Document the supported flags in the body.

## Session shapes

### Shape 1: Adding a new agent
1. Identify the *meta-pattern* you're encoding (not the specific repo it came from). Confirm it generalizes.
2. Create `agents/<name>.md` with frontmatter from the schema above.
3. Body structure: one-line role statement → core approach → 3-7 numbered steps or checklists → constraints → output guidance → memory update guidance.
4. Match the prose style of existing agents (terse, second-person, action-oriented).
5. Update `README.md` agent table and any workflow recipes that reference the new agent.
6. Test it: `./scripts/install.sh --dry-run` should show it would install.

### Shape 2: Upgrading an existing agent
1. Read the agent in full first — don't patch what you haven't understood.
2. Add new sections *after* existing ones where possible; don't reorder unless the existing structure is broken.
3. Preserve the "memory update" guidance at the end of every agent.
4. Run `git diff agents/<name>.md` and re-read — agent prompts are load-bearing; a typo in the rules ships to every session.

### Shape 3: Adding a slash command
1. Decide if it's worth a command vs. an agent. Commands are good for short, parameterized operations the user runs often (commit, branch, worktree). Agents are good for open-ended reasoning that benefits from a system prompt.
2. Create `commands/<name>.md`. The body should document supported flags up front.
3. Always honor `{{RAW_PROMPT}}` for arg parsing.
4. Reference, don't duplicate, conventions documented elsewhere — link to the relevant AGENTS.md section.

### Shape 4: Repo hygiene / docs
1. README.md is the human-facing pitch; AGENTS.md is the agent playbook. Don't mix audiences.
2. The install script auto-discovers files in `agents/`, `commands/`, and `scripts/`. New files install automatically — no install.sh edit needed.
3. Test installer changes with `./scripts/install.sh --dry-run` before committing.

## Decision frameworks

- **Add a new agent vs. extend an existing one?** Extend when the new capability is a refinement (engineer learns a new convention, reviewer learns a new checklist). New agent when the role is fundamentally different (architect ≠ reviewer; security ≠ reviewer).
- **Hardcoded rule vs. discovered rule?** If the rule is in *every* well-run project, hardcode it (e.g., "read CLAUDE.md before starting"). If the rule depends on the project's stack or style, the agent should *discover* it locally.
- **Read-only vs. write-capable agent?** Read-only (no `Write`/`Edit`) for analysis agents (reviewer, security, planner, gap-finder, architect, context-auditor, researcher). Write-capable for execution agents (engineer, debugger, tester, optimizer, documenter, review-responder).
- **Review-responder vs. inline fixup?** Use `review-responder` when a PR has accumulated feedback from multiple sources or tiers (human reviewers, automated/AI review tools, multiple files) — the agent's value is structured triage and tiered commits. For a single one-off comment on a small diff, fixing inline as part of normal engineering work is fine. Once a review crosses ~3 findings or any P1, hand off to `review-responder`.

## Conventions

- **Commits**: conventional commits (`feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci`, `build`, `perf`, `style`, `revert`). Scope is optional and short.
- **Branch naming**: `<type>/<kebab-description>` matching the commit type.
- **One feature per PR.** Large agent rewrites that touch unrelated agents should be split.

## When You're Stuck

Report blocking state explicitly: what completed, what's blocking, what was attempted, what's needed from the user. Don't loop on the same failing command.
