# Claude Agent Team

Specialized AI agents that orchestrate your entire feature development workflow - from PRD to production.

**Your AI engineering team that ships features, not just code.** From PRD to production, these specialized agents handle tech shaping, implementation, testing, review, optimization, and documentation—autonomously executing the full development workflow while you focus on what to build, not how to build it.

> **The quality of your output is directly proportional to the quality of your input.** Give agents clear requirements, context, and goals—they'll handle the rest.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Copy agents**: `cp -r agents/* ~/.claude/agents/`
3. **Copy commands**: `cp -r commands ~/.claude/commands/`

## Agents

| Agent          | Purpose                                                     | Model  | Features                  |
| -------------- | ----------------------------------------------------------- | ------ | ------------------------- |
| **researcher** | Explore codebases, compare technologies, gather information | Sonnet | `memory: user`            |
| **reviewer**   | Code review with confidence-based filtering (≥80 threshold) | Sonnet | `memory: user`, read-only |
| **engineer**   | Implement features following existing codebase patterns     | Sonnet |                           |
| **tester**     | Write unit tests for new functionality                      | Sonnet |                           |
| **optimizer**  | Practical code improvements and refactoring                 | Sonnet | `memory: user`            |

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
