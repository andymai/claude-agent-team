# Claude Agent Team

Specialized AI agents that orchestrate your entire feature development workflow - from PRD to production.

**Think of these agents as teammates, not replacements.** They're specialists who handle tech shaping, planning, implementation, testing, review, optimization, and documentation - with smart auto-delegation between agents. The quality of your output is directly proportional to the quality of your input.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Copy**: `cp -r agents ~/.claude/agents/`
3. **Use**: `/task task-planner https://notion.so/your-tech-shaping-doc`

Agents auto-discover from `~/.claude/agents/`. Optionally add the workflow to `CLAUDE.md` (see bottom) for proactive suggestions.

## Available Agents

| Agent | When to Use | Model | Auto-Delegates |
|-------|-------------|-------|----------------|
| 🔨 engineer | "Implement the auth service" | Sonnet | ✅ tester |
| 🧪 tester | "Write specs for the new API" | Sonnet | ✅ gap-finder |
| 🔍 reviewer | "Review before merging" | Opus | ✅ engineer/optimizer/notion-manager |
| ⚡ optimizer | "Refactor after it works" | Sonnet | ✅ reviewer |
| 📝 documentor | "Document the new feature" | Haiku | ✅ notion-manager |
| 🔌 integration-tester | "Test end-to-end flows" | Sonnet | ❌ |
| 🔎 gap-finder | "Find what's missing vs spec" | Opus | ✅ engineer/reviewer |
| 🎨 tech-shaping-advisor | "Help me draft tech spec sections" | Opus | ❌ |
| 📋 task-planner | "Create implementation plan" | Opus | ❌ |
| 🔄 notion-manager | "Sync status to Notion" | Haiku | ❌ |

## Quick Workflow

**1. Tech Shaping** - Draft tech spec with AI assistance:
```bash
/task tech-shaping-advisor Help me draft technical approach for gift tracking
```

**2. Planning** - Create implementation plan:
```bash
/task task-planner Create plan from https://notion.so/tech-shaping-doc
```

**3. Implementation** - Trigger per branch, rest auto-delegates:
```bash
/task engineer https://notion.so/plan#branch-1
# → Auto-delegates: tester → gap-finder → reviewer → optimizer → notion-manager
```

**4. Integration Testing** - When branches complete:
```bash
/task integration-tester Test end-to-end workflows
```

**5. Documentation** - When all branches merged:
```bash
/task documentor Document the feature
```

## Optional Dependencies

**Notion integration** (tech-shaping-advisor, task-planner, notion-manager):
- [Notion MCP](https://mcp.notion.com/): `claude mcp add -t http notion https://mcp.notion.com/mcp`

**Babylist-specific** (tech-shaping-advisor, task-planner):
- `.knowledge/` directory with codebase patterns
- `.github/prompts/ai_tech_shaping.prompt.md` template

Agents gracefully degrade without these - skipping Notion publishing or using generic patterns.
