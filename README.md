# Claude Code Configuration

Multi-agent orchestration system for AI-assisted software development.

## The 11 Agents

| Agent | Category | Model | Delegation | Purpose |
|-------|----------|-------|------------|---------|
| 🔨 engineer | Core Development | Sonnet 3.5 | ❌ | Writes code following existing patterns |
| 🧪 tester | Core Development | Sonnet 3.5 | ❌ | Writes Rails specs for new functionality |
| 🔍 reviewer | Core Development | Opus | ✅ engineer | Two-phase review process (critique → reflection) |
| ⚡ optimizer | Core Development | Sonnet 3.5 | ✅ engineer | Refactors after implementation |
| 📝 chronicler | Core Development | Sonnet 3.5 | ✅ notion-manager | Creates developer-focused docs |
| 🔌 inspector | Testing & Quality | Sonnet 4.5 | ❌ | Tests cross-component interactions |
| 🔎 auditor | Testing & Quality | Opus | ✅ engineer | Compares implementation to requirements |
| 🎨 tech-shaping-advisor | Planning & Documentation | Opus | ✅ auditor | Creates tech shaping docs from PRDs, publishes to Notion |
| 📋 architect | Planning & Documentation | Opus | ✅ engineer | Breaks features into deployable branches |
| 🛡️ project-manager | Planning & Documentation | Sonnet 4.5 | ❌ | Prevents scope drift during implementation |
| 🔄 notion-manager | Planning & Documentation | Sonnet 4.5 | ❌ | Updates Notion with implementation status |

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
- Delegates to `auditor` for completeness validation

### 2. Tech Shaping → Implementation Plan
- Use `/task architect` to transform tech shaping into implementation plan
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
