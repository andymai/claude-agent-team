<div align="center">

# Skills

Claude Code skills, subagents, slash commands, scripts, and templates, shipped as one plugin named `team`. The subagents (engineer, reviewer, debugger, and more) compose into workflow recipes.

[Agents](#agents) · [Workflow Skills](#workflow-skills) · [Workflow Recipes](#workflow-recipes) · [Quick Start](#quick-start)

</div>

---

This repo is a [Claude Code plugin](https://code.claude.com/docs/en/plugins) containing agent definitions, slash commands, and workflow skills. It doubles as its own marketplace, named `andymai`, so installing it registers the agents in every project you open.

## Quick Start

Requires [Claude Code](https://docs.claude.com/en/docs/claude-code). In any session:

```
/plugin marketplace add andymai/skills
/plugin install team@andymai
```

To pull later changes, refresh the catalog with `/plugin marketplace update andymai`, then update from a shell with `claude plugin update team@andymai` (or pick Update from the `/plugin` menu). Remove everything with `/plugin uninstall team`.

Components are namespaced by the plugin name: commands and skills are `/team:commit`, `/team:shepherd-pr`, and so on; agents are `team:engineer`, `team:reviewer`, and so on.

To work on the plugin itself, load a clone directly for one session: `claude --plugin-dir /path/to/skills`. Installing reads from a copy in the plugin cache, so edits to a clone don't reach an installed copy.

## Agents

| Agent              | Purpose                                                       | Model  | Features        |
| ------------------ | ------------------------------------------------------------- | ------ | --------------- |
| **engineer**       | Implement features and their tests, following existing codebase patterns; test-first for bug fixes | Opus   |                 |
| **debugger**       | Systematic bug investigation — reproduce, fix all layers, real deps only | Opus   |                 |
| **reviewer**       | Code review with confidence-based filtering (≥60 threshold)   | Opus   | read-only       |
| **researcher**     | Explore codebases, compare technologies, gather information   | Opus   | read-only       |
| **gap-finder**     | Verify implementations match specs, find missing requirements | Opus   | read-only       |
| **optimizer**      | Practical code improvements and refactoring                   | Sonnet |                 |

For planning, use plan mode or Claude Code's built-in Plan agent. For a security review, use the built-in `/security-review`.

## Scope

To set expectations, this collection deliberately does not:

- **Replace or install Claude Code**: assumes Claude Code is already installed and authenticated; this repo only adds agent definitions on top of it.
- **Provide a runtime orchestration framework**: agents are static markdown definitions read by Claude Code; there is no daemon, scheduler, or inter-agent message bus.
- **Make workflow recipes executable**: the recipes under [Workflow Recipes](#workflow-recipes) are documentation suggestions showing a useful invocation order, not automated pipelines you can run with a single command.
- **Bootstrap new projects**: the plugin adds agents and commands for use in existing projects; it does not scaffold repos, generate code boilerplate, or configure CI. The **obsidian-project** skill creates planning notes in an Obsidian vault, not code.
- **Work outside Claude Code**: the agent and slash-command formats are specific to Claude Code's subagent protocol and are not compatible with other LLM tooling without modification.

## Workflow Recipes

**Bug fix**:
```
debugger → engineer → reviewer
```

**New feature** (after plan mode):
```
engineer → gap-finder → reviewer
```

**Cleanup after a change**:
```
optimizer → reviewer
```

**Research before a decision**:
```
researcher (standalone)
```

Each agent works autonomously and returns results. Claude Code decides which agent to invoke next.

## Workflow Skills

General-purpose [Agent Skills](https://code.claude.com/docs/en/skills) that aren't tied to a specific stack, available in every project once the plugin is installed. Like all skills they load progressively: only the `description` stays in context until the skill triggers.

| Skill            | Triggers on                                                   | What it does |
| ---------------- | ------------------------------------------------------------- | ------------ |
| **shepherd-pr**  | "shepherd the PR", "drive this PR to green", "clean up the PR" | Autonomous loop that drives the current branch's PR to a clean state — resolves review comments, fixes check-run findings (including neutral-status reviewers the CI rollup hides), and waits on CI — then reassigns and reports. Repo-agnostic: detects Graphite vs plain git and derives the GitHub login at runtime |
| **outward-writing** | the deliverable is prose another person will read: a design doc, proposal, wiki page, Slack message, PR body or reply, review reply, ticket, email | You collect every fact with a source, write the draft in ASD-STE100 Simplified Technical English, fact-check it sentence by sentence, and run `check.py`. Nothing is published until the user has seen the draft. No external CLI is needed |
| **obsidian-project** | "start a project in my vault", "set up project docs in Obsidian" | Creates one folder in an Obsidian vault with five linked notes: the overview, PRD, architecture, research, and tasks. It adds the project to the vault's index. It fills a section only from what you said or what it read, and the other sections keep a hidden prompt. A layout in the vault's own CLAUDE.md wins over the templates |

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

`skills/outward-writing/scripts/check.py` ships with the **outward-writing** skill, reached via `${CLAUDE_PLUGIN_ROOT}`. It fails a draft on em or en dashes outside code and quotes, on a sentence over 25 words, and on a paragraph over 6 sentences. It warns on the present perfect, "-ing" verbs, possible passives, and two verbs for one action, and it reports the word count.

## Contributing

Adding or upgrading an agent? See [AGENTS.md](AGENTS.md) — the playbook for agent authors. Covers the frontmatter schema, model selection, color palette, the **generalization rule** (agents run across every repo you touch, so rules must be portable), and the **weakest-executor rule** (prompts must carry the discipline — evidence rules, hard gates, self-checks — so smaller models and junior engineers succeed with them too).
