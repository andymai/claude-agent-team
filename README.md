# Claude Code Configuration

A multi-agent orchestration system for AI-assisted software development with Claude Code.

## What is this?

This repository contains 11 specialized AI agents that work together to handle the complete software development lifecycle - from PRD to tech shaping, implementation planning, coding, testing, review, and documentation.

**Think of these agents as teammates, not replacements.** They're specialists who collaborate with you, not autopilot that flies solo. Like any great team, the quality of their output depends on the clarity of your input - garbage in, garbage out still applies, but with the right direction, these agents can 10x your velocity.

## Why use this?

**Without agents:** You write prompts for everything, context gets lost, and Claude doesn't know when to switch between planning, coding, reviewing, etc.

**With agents:** Each agent has specialized knowledge and tools. They delegate to each other automatically, maintaining context throughout your feature development workflow.

## Quick Start

1. **Install Claude Code**: Follow [installation instructions](https://docs.claude.com/en/docs/claude-code)
2. **Copy agent configs**: `cp -r agents ~/.claude/agents/`
3. **Optional**: Add the workflow to your `CLAUDE.md` (see Setup section below)
4. **Start using**: `/task task-planner https://notion.so/your-tech-shaping-doc`

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

## Prerequisites

**Required:**
- [Claude Code](https://docs.claude.com/en/docs/claude-code) installed
- Anthropic API key configured

**For Notion-dependent agents** (tech-shaping-advisor, task-planner, notion-manager, project-manager):
- [Notion MCP](https://mcp.notion.com/) configured: `claude mcp add -t http notion https://mcp.notion.com/mcp`
- Notion workspace with access to project pages

**For Babylist-specific features** (tech-shaping-advisor, task-planner):
- `.knowledge/` directory with codebase patterns (see [example structure](https://github.com/babylist/web))
- `.github/prompts/ai_tech_shaping.prompt.md` template

**Note:** Agents gracefully degrade if optional dependencies are missing - they'll skip Notion publishing or use generic patterns instead of codebase-specific ones.

## Setup (Optional)

Agents are automatically discovered from `~/.claude/agents/` based on their frontmatter configuration.

**Optionally add this workflow to your `CLAUDE.md`** to guide Claude on when to proactively suggest each agent:

```markdown
## Agent Workflow

When working on new features, follow this agent orchestration workflow:

### 1. PRD → Tech Shaping
- Use `/task tech-shaping-advisor` to create tech shaping document
- Consults `.knowledge/` patterns for architectural guidance
- Publishes to Notion and links to project page
- Delegates to `gap-finder` for completeness validation

### 2. Tech Shaping → Implementation Plan
- Use `/task task-planner` to transform tech shaping into implementation plan
- Breaks feature into independently deployable branches
- Creates Graphite stacked PR workflow
- Publishes to Notion with status tracking

### 3. Implementation
- Use `/task engineer` for each branch following the plan
- Use `/task project-manager` to enforce scope boundaries during implementation
- Use `/task tester` to write specs after implementation
- Use `/task reviewer` to approve code before merge

### 4. Documentation
- Use `/task chronicler` when implementation is complete
- Automatically delegates to `notion-manager` for status updates
```
