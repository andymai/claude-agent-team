<div align="center">

# Claude Agent Team

A set of Claude Code subagents (planner, engineer, debugger, reviewer, and more), shipped as a plugin and designed to be composed into workflow recipes.

[Agents](#agents) · [Workflow Skills](#workflow-skills) · [Workflow Recipes](#workflow-recipes) · [Quick Start](#quick-start)

</div>

---

This repo is a [Claude Code plugin](https://code.claude.com/docs/en/plugins) containing agent definitions, slash commands, and workflow skills. It doubles as its own marketplace, so installing it registers the agents in every project you open.

## Quick Start

Requires [Claude Code](https://docs.claude.com/en/docs/claude-code). In any session:

```
/plugin marketplace add andymai/claude-agent-team
/plugin install team@claude-agent-team
```

To pull later changes, refresh the catalog with `/plugin marketplace update claude-agent-team`, then update from a shell with `claude plugin update team@claude-agent-team` (or pick Update from the `/plugin` menu). Remove everything with `/plugin uninstall team`.

Components are namespaced by the plugin name: commands and skills are `/team:commit`, `/team:shepherd-pr`, and so on; agents are `team:engineer`, `team:reviewer`, and so on.

To work on the plugin itself, load a clone directly for one session: `claude --plugin-dir /path/to/claude-agent-team`. Installing reads from a copy in the plugin cache, so edits to a clone don't reach an installed copy.

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
| **researcher**     | Explore codebases, compare technologies, gather information   | Opus   | read-only       |
| **gap-finder**     | Verify implementations match specs, find missing requirements | Opus   | read-only       |
| **optimizer**      | Practical code improvements and refactoring                   | Sonnet |                 |
| **documenter**     | Create and maintain documentation, diagrams, and guides       | Sonnet |                 |
| **context-auditor**| Audit markdown docs for token efficiency and redundancy       | Sonnet | read-only       |

## Scope

To set expectations, this collection deliberately does not:

- **Replace or install Claude Code**: assumes Claude Code is already installed and authenticated; this repo only adds agent definitions on top of it.
- **Provide a runtime orchestration framework**: agents are static markdown definitions read by Claude Code; there is no daemon, scheduler, or inter-agent message bus.
- **Make workflow recipes executable**: the recipes under [Workflow Recipes](#workflow-recipes) are documentation suggestions showing a useful invocation order, not automated pipelines you can run with a single command.
- **Bootstrap new projects**: the plugin adds agents and commands for use in existing projects; it does not scaffold repos, generate boilerplate, or configure CI.
- **Work outside Claude Code**: the agent and slash-command formats are specific to Claude Code's subagent protocol and are not compatible with other LLM tooling without modification.

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

Each agent works autonomously and returns results. Claude Code decides which agent to invoke next.

## Workflow Skills

General-purpose [Agent Skills](https://code.claude.com/docs/en/skills) that aren't tied to a specific stack, available in every project once the plugin is installed. Like all skills they load progressively: only the `description` stays in context until the skill triggers.

| Skill            | Triggers on                                                   | What it does |
| ---------------- | ------------------------------------------------------------- | ------------ |
| **shepherd-pr**  | "shepherd the PR", "drive this PR to green", "clean up the PR" | Autonomous loop that drives the current branch's PR to a clean state — resolves review comments, fixes check-run findings (including neutral-status reviewers the CI rollup hides), and waits on CI — then reassigns and reports. Repo-agnostic: detects Graphite vs plain git and derives the GitHub login at runtime |

## Slash Commands

| Command                     | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| `/team:audit-claudemd`      | Audit or bootstrap the project's CLAUDE.md against observed conventions |
| `/team:branch`              | Create a branch following `<type>/<kebab-description>` naming |
| `/team:check`               | Run the project's local quality gate (auto-detected)          |
| `/team:commit`              | Create a conventional commit from working tree changes        |
| `/team:contribution-report` | GitHub contribution summaries for performance reviews         |
| `/team:pr-description`      | Generate PR title and description from branch changes         |
| `/team:upgrade-dep`         | Upgrade a dependency and fix breaking changes                 |
| `/team:worktree`            | Set up a git worktree under `.worktrees/` for parallel work   |

## Scripts

`scripts/count-tokens.sh` ships with the plugin and is called by the **context-auditor** agent via `${CLAUDE_PLUGIN_ROOT}`. It counts tokens with the Anthropic API when `ANTHROPIC_API_KEY` is set, caches results, and falls back to a character-based estimate otherwise.

## Contributing

Adding or upgrading an agent? See [AGENTS.md](AGENTS.md) — the playbook for agent authors. Covers the frontmatter schema, model selection, color palette, the **generalization rule** (agents run across every repo you touch, so rules must be portable), and the **weakest-executor rule** (prompts must carry the discipline — evidence rules, hard gates, self-checks — so smaller models and junior engineers succeed with them too).
