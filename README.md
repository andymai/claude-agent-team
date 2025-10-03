# Claude Code Configuration

Eleven specialized AI agents that orchestrate your entire feature development workflow - from PRD to production.

**Think of these agents as teammates, not replacements.** They're specialists who collaborate with you, not autopilot that flies solo. Like any great team, the quality of their output depends on the clarity of your input - garbage in, garbage out still applies, but with the right direction, these agents can 10x your velocity.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Copy**: `cp -r agents ~/.claude/agents/`
3. **Use**: `/task task-planner https://notion.so/your-tech-shaping-doc`

Agents auto-discover from `~/.claude/agents/`. Optionally add the workflow to `CLAUDE.md` (see bottom) for proactive suggestions.

## The 11 Agents

| Agent | Category | Model | Delegation | Purpose |
|-------|----------|-------|------------|---------|
| 🔨 engineer | Core Development | Sonnet 3.5 | ❌ | Writes code following existing patterns |
| 🧪 tester | Core Development | Sonnet 3.5 | ❌ | Writes Rails specs for new functionality |
| 🔍 reviewer | Core Development | Opus | ✅ engineer | Two-phase review process (critique → reflection) |
| ⚡ optimizer | Core Development | Sonnet 3.5 | ✅ engineer | Refactors after implementation |
| 📝 chronicler | Core Development | Sonnet 3.5 | ✅ notion-manager | Creates developer-focused docs |
| 🔌 integration-tester | Testing & Quality | Sonnet 4.5 | ❌ | Tests cross-component interactions |
| 🔎 gap-finder | Testing & Quality | Opus | ✅ engineer | Compares implementation to requirements |
| 🎨 tech-shaping-advisor | Planning & Documentation | Opus | ✅ gap-finder | Creates tech shaping docs from PRDs, publishes to Notion |
| 📋 task-planner | Planning & Documentation | Opus | ✅ engineer | Breaks features into independently deployable branches |
| 🛡️ project-manager | Planning & Documentation | Sonnet 4.5 | ❌ | Prevents scope drift during implementation |
| 🔄 notion-manager | Planning & Documentation | Sonnet 4.5 | ❌ | Updates Notion with implementation status |

## Example Usage

### Creating an implementation plan from tech shaping:
```bash
$ /task task-planner Read the tech shaping doc at https://notion.so/project/tech-shaping and create an implementation plan
```

**Output:**
- Notion implementation plan with branch-by-branch breakdown
- Graphite workflow for stacked PRs
- Mermaid dependency diagrams
- Status tracking per branch

### Implementing a feature branch:
```bash
$ /task engineer Implement Branch 1 from the implementation plan: Core Service
```

**Output:**
- Files created/modified following codebase patterns
- Consults `.knowledge/` for conventions
- Ready for review

### Reviewing before merge:
```bash
$ /task reviewer Review the changes in this branch
```

**Output:**
- Two-phase review (critique → reflection)
- Specific file:line references
- Approve/Request Changes decision

## Optional Dependencies

**Notion integration** (tech-shaping-advisor, task-planner, notion-manager, project-manager):
- [Notion MCP](https://mcp.notion.com/): `claude mcp add -t http notion https://mcp.notion.com/mcp`

**Babylist-specific** (tech-shaping-advisor, task-planner):
- `.knowledge/` directory with codebase patterns
- `.github/prompts/ai_tech_shaping.prompt.md` template

Agents gracefully degrade without these - skipping Notion publishing or using generic patterns.

## Workflow (Add to CLAUDE.md)

Add this to your `CLAUDE.md` so Claude proactively suggests the right agent at the right time:

```markdown
## Agent Workflow

When working on new features, follow this agent orchestration workflow:

### 1. PRD → Tech Shaping
- Use `/task tech-shaping-advisor` to create tech shaping document
- Delegates to `gap-finder` for validation

### 2. Tech Shaping → Implementation Plan
- Use `/task task-planner` to break into deployable branches
- Creates Graphite workflow + Notion tracking

### 3. Implementation
- Use `/task engineer` for each branch
- Use `/task project-manager` to enforce scope
- Use `/task tester` for specs
- Use `/task reviewer` before merge

### 4. Documentation
- Use `/task chronicler` when complete
- Delegates to `notion-manager` for updates
```
