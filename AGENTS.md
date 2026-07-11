# AGENTS.md

A playbook for AI agents working on `claude-agent-team` itself. CLAUDE.md (when present) is shared human+agent guidance; this file is agent-specific.

## At a glance

- **What this repo is**: a curated bundle of Claude Code agent definitions (`agents/*.md`), slash commands (`commands/*.md`), and Unity skills (`skills/*/SKILL.md`), installed into `~/.claude/` via `scripts/install.sh`.
- **Distribution model**: agents, commands, and skills ship to `~/.claude/agents/`, `~/.claude/commands/`, and `~/.claude/skills/` and run **across every project the user touches**. They must be portable (skills are Unity-scoped by design, but must be portable across Unity projects).
- **The hard rule**: agents must not encode project-specific conventions. Read the local project's `CLAUDE.md`/`AGENTS.md` and follow *that*.

## The Generalization Rule

Every agent here is loaded by every Claude session for every repo. So:

- Don't hardcode language-specific rules. `unwrap()` is a Rust concept; `any` is TS-specific. Say "no panics in library code if the project bans them" — let the project's docs supply the specifics.
- Don't hardcode tool names. `pnpm`, `cargo`, `just` don't all exist everywhere. Say "the project's check command" and detect it.
- Don't hardcode paths. `src/core/store/` makes sense in gridfinity; nowhere else.
- Do encode **meta-patterns**: "find the project's error-handling convention before writing", "discover where tests live before placing one", "prefer property-based testing where the project already uses it."

When you upgrade an agent, ask: *would this rule make sense in a brand-new repo with a different stack?* If no, generalize it.

## Write for the Weakest Executor

These agents run under whatever model the user has selected — including smaller/faster ones — and their reports are read by engineers at every experience level. The prompt must carry the discipline that a strong executor would supply on its own. Author every rule so the least capable executor still succeeds:

- **Procedures over judgment.** "Use your best judgment" and "when appropriate" only work for strong executors. Convert judgment calls into observable criteria and decision rules: "if X (which you can check by running Y) → do A; otherwise → do B."
- **Hard gates, not implied sequencing.** Assume the executor will skip any step that isn't a named gate. Sequenced work needs explicit preconditions: "Do not proceed to step 3 until the step-2 command exited 0 and you have read its output."
- **Evidence rules.** Every claim in a report must be traceable to something the agent observed *this session* — a file it Read, a Grep hit, quoted command output. Write rules that force this: "cite only file:line you have opened", "quote the failing line verbatim", "paste the test runner's summary line."
- **Anti-fabrication rules.** Weaker executors hallucinate APIs, file paths, and CVEs from training-data memory. Require verification before use: grep for an existing usage in the repo, read the dependency's types/source, or fetch current docs. Memory of a library is a hypothesis, not a fact.
- **Permission to not know.** Weaker executors guess plausibly instead of admitting uncertainty. Every agent must explicitly prefer "I could not determine X (I tried A and B)" over a confident guess, and reports must label each claim **verified** (observed), **inferred** (from code read), or **assumed** (stated as such).
- **Worked examples.** Weak executors follow examples better than abstractions. Every non-obvious rule should carry a short good/bad pair showing exactly what compliance looks like.
- **Anti-thrash circuit breakers.** Strong executors notice when they're looping; weak ones don't. Encode explicit limits: "if two consecutive fix attempts don't change the symptom, revert and re-diagnose", "escalate after the third failed command."
- **Final self-check.** End every agent with a short checklist it runs against its own output before reporting done. "Be careful" is not a step; a checklist is.

Verbosity is acceptable here: agent bodies load only when the agent is invoked, and a rule that prevents one hallucinated API call pays for itself. Keep the *frontmatter description* lean (it's always in context); spend tokens freely in the body where they buy correctness.

## Frontmatter Schema

### Agents (`agents/*.md`)

```yaml
---
name: <kebab-case>              # required, matches filename without .md
description: <one paragraph>    # required, used by Claude to decide when to invoke
tools: <comma-separated>        # required, see allowed tools below
disallowedTools: <list>         # optional hard-deny — see caveat below before using
model: opus | sonnet | haiku    # required, see model selection below
color: <ANSI color>             # required, see palette below
---
```

**Allowed tool names**: `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `WebSearch`, `WebFetch`. (Don't list tools the agent never uses — the description should make use of every listed tool.)

**Read-only agents are enforced by omission, not `disallowedTools`.** The `tools:` list is an allowlist, so leaving out `Write`/`Edit` already makes an agent read-only. Don't add `disallowedTools: Write, Edit` on top — it's redundant. Reserve `disallowedTools` for blocking a tool that would otherwise be *inherited* when no `tools:` allowlist is set.

**Model selection**:
- `opus` — reasoning-heavy work: planning, architecture, debugging, security, review, research, gap-finding.
- `sonnet` — pattern-following work where speed matters: testing, optimization, documentation, context audits.
- `haiku` — short, deterministic transforms only (currently unused here).

**Color palette** (chosen for visual distinction in the agent picker):
- `green` / `brightGreen` — building (engineer, documenter)
- `red` / `brightRed` — finding problems (reviewer, debugger)
- `brightYellow` / `yellow` — testing/security (security, tester)
- `cyan` / `brightCyan` / `brightBlue` / `blue` — planning/research/architecture (optimizer, planner, architect, researcher)
- `magenta` — gap-finding (post-implementation verification)
- `white` — auditing (context-auditor)

Avoid duplicating colors across agents that the user might invoke in the same workflow.

### Commands (`commands/*.md`)

```yaml
---
description: <one short line>    # required
---
```

Commands receive the raw user prompt via `{{RAW_PROMPT}}`. Document the supported flags in the body.

## Session shapes

### Shape 1: Adding a new agent
1. Identify the *meta-pattern* you're encoding (not the specific repo it came from). Confirm it generalizes.
2. Create `agents/<name>.md` with frontmatter from the schema above.
3. Body structure: one-line role statement → core approach → 3-7 numbered steps or checklists → constraints → output guidance.
4. Match the prose style of existing agents (terse, second-person, action-oriented).
5. Update `README.md` agent table and any workflow recipes that reference the new agent.
6. Test it: `./scripts/install.sh --dry-run` should show it would install.

### Shape 2: Upgrading an existing agent
1. Read the agent in full first — don't patch what you haven't understood.
2. Add new sections *after* existing ones where possible; don't reorder unless the existing structure is broken.
3. Run `git diff agents/<name>.md` and re-read — agent prompts are load-bearing; a typo in the rules ships to every session.

### Shape 3: Adding a slash command
1. Decide if it's worth a command vs. an agent. Commands are good for short, parameterized operations the user runs often (commit, branch, worktree). Agents are good for open-ended reasoning that benefits from a system prompt.
2. Create `commands/<name>.md`. The body should document supported flags up front.
3. Always honor `{{RAW_PROMPT}}` for arg parsing.
4. Reference, don't duplicate, conventions documented elsewhere — link to the relevant AGENTS.md section.

### Shape 4: Repo hygiene / docs
1. README.md is the human-facing pitch; AGENTS.md is the agent playbook. Don't mix audiences.
2. The install script auto-discovers files in `agents/`, `commands/`, `scripts/`, and `skills/`. New files install automatically — no install.sh edit needed.
3. Test installer changes with `./scripts/install.sh --dry-run` before committing.

## Decision frameworks

- **Add a new agent vs. extend an existing one?** Extend when the new capability is a refinement (engineer learns a new convention, reviewer learns a new checklist). New agent when the role is fundamentally different (architect ≠ reviewer; security ≠ reviewer).
- **Hardcoded rule vs. discovered rule?** If the rule is in *every* well-run project, hardcode it (e.g., "read CLAUDE.md before starting"). If the rule depends on the project's stack or style, the agent should *discover* it locally.
- **Read-only vs. write-capable agent?** Read-only (omit `Write`/`Edit` from `tools:`) for analysis agents (reviewer, security, planner, gap-finder, architect, context-auditor, researcher). Write-capable for execution agents (engineer, debugger, tester, optimizer, documenter).

## Conventions

- **Commits**: conventional commits (`feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci`, `build`, `perf`, `style`, `revert`). Scope is optional and short.
- **Branch naming**: `<type>/<kebab-description>` matching the commit type.
- **One feature per PR.** Large agent rewrites that touch unrelated agents should be split.
- **Never reply to or post PR comments.** Agents and commands must not post comments, reply to review threads, or resolve threads on a PR (`gh pr comment`, `gh api .../comments`, etc.). Address review feedback through commits and report the resolution back to the user; the user owns all PR conversation.

## When You're Stuck

Report blocking state explicitly: what completed, what's blocking, what was attempted, what's needed from the user. Don't loop on the same failing command.
