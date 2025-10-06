# Claude Agent Team

Specialized AI agents that orchestrate your entire feature development workflow - from PRD to production.

**Think of these agents as teammates, not replacements.** They're specialists who handle tech shaping, planning, implementation, testing, review, optimization, and documentation. Claude Code orchestrates them hierarchically - the main agent delegates to specialist agents based on your requests and the workflow defined in `CLAUDE.md`. The quality of your output is directly proportional to the quality of your input.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Copy agents**: `cp -r agents ~/.claude/agents/`
3. **Copy orchestration guide**: `cp CLAUDE.md ~/.claude/CLAUDE.md`
4. **Use**: "Implement authentication following the agent workflow"

Agents auto-discover from `~/.claude/agents/`. The `CLAUDE.md` file tells Claude Code when to proactively invoke each agent.

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

## How Claude Code Orchestrates Agents

Claude Code uses a **hierarchical delegation model**:
- The **main agent** (Claude Code) orchestrates all specialist agents
- Specialist agents **cannot delegate to each other** - they return results to the main agent
- The main agent decides which agent to invoke next based on context and `CLAUDE.md` guidance

### Getting Agents to Trigger Automatically

**Use natural language that matches agent purposes:**

```bash
# Triggers engineer agent
"Implement the authentication system"
"Build the user profile feature"

# Triggers reviewer agent
"Review this code before merging"
"Is this implementation ready?"

# Triggers gap-finder agent
"Did I miss anything from the spec?"
"Check if the implementation is complete"

# Triggers tester agent (usually auto-triggered after engineer)
"Write tests for this feature"
```

**Set completion criteria that require agent chains:**

```bash
# Forces: engineer → tester → gap-finder → reviewer
"Implement authentication. It's not done until tested and reviewed."

# Forces full workflow
"Build the gift tracking feature following the agent workflow"
```

**Reference the workflow explicitly:**

```bash
"Follow the agent orchestration workflow from CLAUDE.md"
```

### Agent Invocation Flow

When you say "Implement the auth feature":

1. Main agent invokes **engineer** to implement
2. Engineer returns implementation results
3. Main agent invokes **tester** to write tests
4. Tester returns test results
5. Main agent invokes **gap-finder** to verify completeness
6. Gap-finder returns analysis
7. Main agent invokes **reviewer** to review code
8. Reviewer returns review decision
9. Main agent reports final status to you

Each agent works autonomously and returns comprehensive results. The main agent orchestrates the sequence.

## Customizing Agent Behavior

### CLAUDE.md Configuration

The `CLAUDE.md` file in `~/.claude/` controls agent orchestration:

- **Auto-trigger rules**: When to invoke each agent
- **Trigger phrases**: Keywords that activate agents
- **Completion criteria**: What "done" means
- **Workflow examples**: How requests should flow through agents

Edit `~/.claude/CLAUDE.md` to customize orchestration for your workflow.

### Agent Descriptions

Each agent's frontmatter `description` field tells Claude Code when to use it:

```yaml
---
name: engineer
description: USE PROACTIVELY for implementation tasks. Implements features based on detailed specifications by reading context, exploring codebase patterns, and writing working code that follows existing conventions.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---
```

The more explicit the description about when to trigger, the better Claude Code can orchestrate.

## Tips for Maximum Agent Usage

1. **Be explicit about workflows**: "Implement, test, and review this feature"
2. **Use trigger phrases**: "build", "review", "optimize", "document"
3. **Set quality gates**: "Not done until tests pass and code is reviewed"
4. **Reference CLAUDE.md**: "Follow the agent workflow"
5. **Mention agents by name**: "Use the reviewer agent to check this"
6. **Structure large tasks**: "Plan this feature, then implement each branch"

## Architecture Notes

- **Hierarchical delegation**: Main agent → specialist agents (not agent-to-agent)
- **Agent discovery**: Agents auto-load from `~/.claude/agents/*.md`
- **Stateless execution**: Each agent starts with clean context
- **Result-based flow**: Agents return results; main agent decides next steps
- **Model selection**: Critical agents use Opus, routine tasks use Sonnet/Haiku
