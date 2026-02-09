# Claude Agent Team

Lean set of specialized AI agents for Claude Code, optimized for Opus 4.6.

## Quick Start

1. Install [Claude Code](https://docs.claude.com/en/docs/claude-code)
2. Copy agents: `cp -r agents/* ~/.claude/agents/`
3. Copy commands: `cp -r commands ~/.claude/commands/`

## Agents

| Agent          | Purpose                                                     | Model  | Features                  |
| -------------- | ----------------------------------------------------------- | ------ | ------------------------- |
| **researcher** | Explore codebases, compare technologies, gather information | Sonnet | `memory: user`            |
| **reviewer**   | Code review with confidence-based filtering (≥80 threshold) | Sonnet | `memory: user`, read-only |
| **engineer**   | Implement features following existing codebase patterns     | Sonnet |                           |
| **tester**     | Write unit tests for new functionality                      | Sonnet |                           |
| **optimizer**  | Practical code improvements and refactoring                 | Sonnet | `memory: user`            |

### Design Principles

- **Concise prompts** — Opus 4.6 is naturally thorough; only tell it what it doesn't already know
- **3-5 agents max** — more agents = slower routing decisions and more misroutes
- **Generic, not project-specific** — agents work across any codebase
- **New frontmatter features** — `memory`, `maxTurns`, `disallowedTools` for better control
- **No `Task` tool** — subagents cannot spawn other subagents

### Workflow

```
"Implement the auth feature and make sure it's tested and reviewed"
→ engineer implements → tester writes tests → reviewer reviews
```

Each agent works autonomously and returns results. Claude Code decides which agent to invoke next.

## Slash Commands

| Command                | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `/contribution-report` | GitHub contribution summaries for performance reviews        |
| `/pr-description`      | Generate PR title and description from branch changes        |
| `/check-deps`          | Audit dependencies for outdated packages and vulnerabilities |
| `/security-scan`       | Quick security audit for common vulnerabilities              |
| `/find-dead-code`      | Find unused exports and orphaned files                       |
| `/find-todos`          | Find and organize TODO/FIXME/HACK annotations                |
| `/explain-error`       | Decode error messages in context of your codebase            |
| `/debug-test`          | Analyze failing tests and identify root cause                |
| `/env-template`        | Generate `.env.example` by scanning for env var usage        |
| `/mock-api`            | Generate mock API responses from types or schemas            |
| `/upgrade-dep`         | Upgrade a dependency and fix breaking changes                |

## Scripts

| Script                    | Description                                                                  |
| ------------------------- | ---------------------------------------------------------------------------- |
| `scripts/count-tokens.sh` | Token counting with Anthropic API (caches results, falls back to estimation) |
