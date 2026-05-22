<div align="center">

# Claude Agent Team

A set of Claude Code subagents (planner, engineer, debugger, reviewer, and more) installed via `./scripts/install.sh`, designed to be composed into workflow recipes.

[Agents](#agents) · [Workflow Recipes](#workflow-recipes) · [Quick Start](#quick-start)

</div>

---

This repo contains agent definitions and slash commands for [Claude Code](https://docs.claude.com/en/docs/claude-code). Running `./scripts/install.sh` copies them into `~/.claude/`, where Claude Code picks them up as project-scoped subagents. Agents use project-scoped memory (`memory: local`) so codebase patterns learned in one project don't bleed into another.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Run**: `./scripts/install.sh`

Tracks checksums so re-running safely updates changed files without clobbering local edits. See `./scripts/install.sh --help` for `--status`, `--uninstall`, `--dry-run`, and `--verbose`.

## Agents

| Agent              | Purpose                                                       | Model  | Features        |
| ------------------ | ------------------------------------------------------------- | ------ | --------------- |
| **planner**        | Design implementation plans, classify session shape, ordered tasks | Opus   | read-only       |
| **architect**      | Audit layer boundaries, dependency directions, module coupling | Opus   | read-only       |
| **engineer**       | Implement features following existing codebase patterns       | Opus   |                 |
| **debugger**       | Systematic bug investigation — reproduce, fix all layers, real deps only | Opus   |                 |
| **tester**         | Write unit tests for new functionality                        | Sonnet |                 |
| **reviewer**       | Code review with confidence-based filtering (≥60 threshold)   | Opus   | read-only       |
| **security**       | Security audit — OWASP Top 10, auth flows, dependency risks  | Opus   | read-only       |
| **researcher**     | Explore codebases, compare technologies, gather information   | Opus   |                 |
| **gap-finder**     | Verify implementations match specs, find missing requirements | Opus   | read-only       |
| **review-responder**| Parse PR review feedback, triage by severity, apply as one commit per tier | Opus   |                 |
| **optimizer**      | Practical code improvements and refactoring                   | Sonnet |                 |
| **documenter**     | Create and maintain documentation, diagrams, and guides       | Sonnet |                 |
| **context-auditor**| Audit markdown docs for token efficiency and redundancy       | Sonnet | read-only       |

All agents use project-scoped memory (`memory: local`) to learn codebase patterns across sessions without cross-project contamination.

## Scope

To set expectations, this collection deliberately does not:

- **Replace or install Claude Code** — assumes Claude Code is already installed and authenticated; this repo only adds agent definitions on top of it.
- **Provide a runtime orchestration framework** — agents are static markdown definitions read by Claude Code; there is no daemon, scheduler, or inter-agent message bus.
- **Make workflow recipes executable** — the recipes under [Workflow Recipes](#workflow-recipes) are documentation suggestions showing a useful invocation order, not automated pipelines you can run with a single command.
- **Bootstrap new projects** — the installer copies files into `~/.claude/` for use in existing projects; it does not scaffold repos, generate boilerplate, or configure CI.
- **Work outside Claude Code** — the agent and slash-command formats are specific to Claude Code's subagent protocol and are not compatible with other LLM tooling without modification.

## Workflow Recipes

**Bug fix**:
```
debugger → engineer → tester → reviewer
```

**New feature**:
```
planner → engineer → tester → gap-finder → reviewer
```

**Security review**:
```
security → reviewer
```

**Architecture audit** (for layered codebases):
```
architect → reviewer
```

**Documentation**:
```
documenter (standalone or after feature work)
```

**PR review response**:
```
review-responder (→ tester for substantial new coverage)
```

Each agent works autonomously and returns results. Claude Code decides which agent to invoke next.

## Slash Commands

| Command                | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `/branch`              | Create a branch following `<type>/<kebab-description>` naming |
| `/check`               | Run the project's local quality gate (auto-detected)          |
| `/commit`              | Create a conventional commit from working tree changes        |
| `/contribution-report` | GitHub contribution summaries for performance reviews         |
| `/pr-description`      | Generate PR title and description from branch changes         |
| `/respond-review`      | Parse PR review feedback and apply fixes as one commit per severity tier |
| `/upgrade-dep`         | Upgrade a dependency and fix breaking changes                 |
| `/worktree`            | Set up a git worktree under `.worktrees/` for parallel work   |

## Scripts

| Script                    | Description                                                                  |
| ------------------------- | ---------------------------------------------------------------------------- |
| `scripts/install.sh`      | Install/update/uninstall agents, commands, and scripts with checksum-based conflict detection |
| `scripts/count-tokens.sh` | Token counting with Anthropic API (caches results, falls back to estimation)       |

## Contributing

Adding or upgrading an agent? See [AGENTS.md](AGENTS.md) — the playbook for agent authors. Covers the frontmatter schema, model selection, color palette, and the **generalization rule** (agents run across every repo you touch, so rules must be portable).
