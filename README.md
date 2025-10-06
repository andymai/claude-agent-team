# Claude Agent Team

Specialized AI agents that orchestrate your entire feature development workflow - from PRD to production.

**Your AI engineering team that ships features, not just code.** From PRD to production, these specialized agents handle tech shaping, implementation, testing, review, optimization, and documentation—autonomously executing the full development workflow while you focus on what to build, not how to build it.

> **The quality of your output is directly proportional to the quality of your input.** Give agents clear requirements, context, and goals—they'll handle the rest.

## Quick Start

1. **Install**: [Claude Code](https://docs.claude.com/en/docs/claude-code) + Anthropic API key
2. **Copy agents**: `cp -r agents ~/.claude/agents/`
3. **Copy orchestration guide**: `cp CLAUDE.md ~/.claude/CLAUDE.md`
4. **Use**: "Implement authentication following the agent workflow"

Agents auto-discover from `~/.claude/agents/`. The `CLAUDE.md` file guides Claude Code on when to consider invoking each agent.

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

**1. Tech Shaping**
```
You: "Help me draft a technical approach for the gift tracking feature based on this PRD..."
Claude Code: [invokes tech-shaping-advisor to research patterns and draft sections]
```

**2. Planning**
```
You: "Create an implementation plan from this tech shaping doc"
Claude Code: [invokes task-planner to break down into branches with acceptance criteria]
```

**3. Implementation**
```
You: "Implement the first branch and make sure it's tested and reviewed"
Claude Code: [invokes engineer]
             [engineer returns implementation]
             [invokes tester based on CLAUDE.md guidance]
             [tester returns test results]
             [invokes gap-finder]
             [gap-finder returns completeness check]
             [invokes reviewer]
             [reviewer returns approval/changes needed]
```

**4. Integration Testing**
```
You: "Test the end-to-end gift tracking workflows"
Claude Code: [invokes integration-tester to create and run integration tests]
```

**5. Documentation**
```
You: "Document the gift tracking feature now that all branches are merged"
Claude Code: [invokes documentor to verify merges, write docs, and suggest Notion sync]
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

### Encouraging Claude Code to Use Agents

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

# Triggers tester agent
"Write tests for this feature"
```

**Set completion criteria to encourage agent chains:**

```bash
# Encourages: engineer → tester → gap-finder → reviewer
"Implement authentication. It's not done until tested and reviewed."

# Encourages full workflow
"Build the gift tracking feature following the agent workflow"
```

**Reference the workflow explicitly:**

```bash
"Follow the agent orchestration workflow from CLAUDE.md"
```

### Agent Invocation Flow (Example)

When you say "Implement the auth feature and make sure it's tested and reviewed", Claude Code might:

1. Invoke **engineer** to implement
2. Receive implementation results from engineer
3. Decide to invoke **tester** (based on "make sure it's tested" + CLAUDE.md guidance)
4. Receive test results from tester
5. Decide to invoke **gap-finder** to verify completeness
6. Receive completeness analysis from gap-finder
7. Decide to invoke **reviewer** (based on "reviewed" + CLAUDE.md guidance)
8. Receive review decision from reviewer
9. Report final status to you

Each agent works autonomously and returns comprehensive results. Claude Code makes sequential decisions about which agent to invoke next based on your request, agent descriptions, CLAUDE.md guidance, and the results received so far.

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
