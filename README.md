# Claude Agent Team

Specialized AI agents that orchestrate your entire feature development workflow - from PRD to production.

**Think of these agents as teammates, not replacements.** They're specialists who handle tech shaping, planning, implementation, testing, review, optimization, and documentation - with smart auto-delegation between agents. The quality of your output is directly proportional to the quality of your input.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Copy**: `cp -r agents ~/.claude/agents/`
3. **Use**: `/task task-planner https://notion.so/your-tech-shaping-doc`

Agents auto-discover from `~/.claude/agents/`. Optionally add the workflow to `CLAUDE.md` (see bottom) for proactive suggestions.

## Available Agents

| Agent | When to Use | Model |
|-------|-------------|-------|
| 🔨 engineer | "Implement the auth service" | Sonnet |
| 🧪 tester | "Write specs for the new API" | Sonnet |
| 🔍 reviewer | "Review before merging" | Opus |
| ⚡ optimizer | "Refactor after it works" | Sonnet |
| 📝 documentor | "Document the new feature" | Haiku |
| 🔌 integration-tester | "Test end-to-end flows" | Sonnet |
| 🔎 gap-finder | "Find what's missing vs spec" | Opus |
| 🎨 tech-shaping-advisor | "Help me draft tech spec sections" | Opus |
| 📋 task-planner | "Create implementation plan" | Opus |
| 🔄 notion-manager | "Sync status to Notion" | Haiku |

## Quick Workflow

**1. Tech Shaping** - Draft tech spec with AI assistance:
```
Help me draft a technical approach for the gift tracking feature based on this PRD...
→ tech-shaping-advisor assists with pattern research and section drafting
```

**2. Planning** - Create implementation plan:
```
Create an implementation plan from https://notion.so/tech-shaping-doc
→ task-planner breaks down into branches with acceptance criteria
```

**3. Implementation** - Claude Code orchestrates specialists:
```
Implement the first branch from https://notion.so/plan#branch-1
→ Claude Code delegates: engineer → tester → gap-finder → reviewer → optimizer → notion-manager
```

**4. Integration Testing** - Test cross-component interactions:
```
Test the end-to-end gift tracking workflows
→ integration-tester creates integration tests
```

**5. Documentation** - Document completed feature:
```
Document the gift tracking feature now that all branches are merged
→ documentor verifies all merged, creates docs, updates Notion
```

## Optional Dependencies

**Notion integration** (tech-shaping-advisor, task-planner, notion-manager):
- [Notion MCP](https://mcp.notion.com/): `claude mcp add -t http notion https://mcp.notion.com/mcp`

**Babylist-specific** (tech-shaping-advisor, task-planner):
- `.knowledge/` directory with codebase patterns
- `.github/prompts/ai_tech_shaping.prompt.md` template

Agents gracefully degrade without these - skipping Notion publishing or using generic patterns.
