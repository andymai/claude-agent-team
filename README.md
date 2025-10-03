# Claude Code Configuration

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
