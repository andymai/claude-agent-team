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

## Setup

**Add this workflow to your `CLAUDE.md` file** so Claude automatically follows it:

```markdown
### Feature Development Workflow

Follow this agent workflow for new features:

1. **PRD → Tech Shaping**: Use `tech-shaping-advisor` to create tech shaping doc
   - Consults `.knowledge/` patterns
   - Publishes to Notion linked to project page
   - Delegates to `auditor` for validation

2. **Tech Shaping → Implementation Plan**: Use `architect` to create implementation plan
   - Breaks into independently deployable branches
   - Creates Graphite workflow
   - Publishes to Notion with status tracking

3. **Implementation**: Use `engineer` for each branch
   - `project-manager` enforces scope boundaries
   - `tester` writes specs after implementation
   - `reviewer` approves before merge

4. **Documentation**: Use `chronicler` when implementation complete
   - Delegates to `notion-manager` for status updates
```
