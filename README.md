# Claude Code Configuration

## The 10 Agents

| Agent | Category | Model | Delegation | Purpose |
|-------|----------|-------|------------|---------|
| 🔨 scaffolder | Core Development | Sonnet 3.5 | ❌ | Writes code following existing patterns |
| 🧪 test-engineer | Core Development | Sonnet 3.5 | ❌ | Writes Rails specs for new functionality |
| 🔍 reviewer | Core Development | Opus | ✅ scaffolder | Two-phase review process (critique → reflection) |
| ⚡ optimizer | Core Development | Sonnet 3.5 | ✅ scaffolder | Refactors after implementation |
| 📝 documenter | Core Development | Sonnet 3.5 | ✅ notion-sync | Creates developer-focused docs |
| 🔌 integration-tester | Testing & Quality | Sonnet 4.5 | ❌ | Tests cross-component interactions |
| 🔎 gap-finder | Testing & Quality | Opus | ✅ scaffolder | Compares implementation to requirements |
| 📋 implementation-planner | Planning & Documentation | Opus | ✅ scaffolder | Breaks features into deployable branches |
| 🛡️ plan-keeper | Planning & Documentation | Sonnet 4.5 | ❌ | Prevents scope drift during implementation |
| 🔄 notion-sync | Planning & Documentation | Sonnet 4.5 | ❌ | Updates Notion with implementation status |
