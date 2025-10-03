# Claude Code Configuration

Personal configuration for [Claude Code](https://claude.ai/code) multi-agent orchestration system.

## Overview

This repository contains 10 specialized agents that handle different aspects of software development. Each agent focuses on a specific responsibility and can be invoked automatically when appropriate.

## Agent Architecture

### Model Assignments

**Opus** (highest complexity reasoning):
- **reviewer** - Two-phase critique + reflection, security analysis, complex judgment
- **implementation-planner** - Complex decomposition, dependency mapping, architectural decisions
- **gap-finder** - Systematic requirement tracing, completeness verification

**Sonnet 4.5** (strong reasoning, efficient):
- **integration-tester** - Multi-component analysis, complex test scenarios
- **plan-keeper** - Specification interpretation and boundary enforcement
- **notion-sync** - Context synthesis and documentation alignment

**Sonnet 3.5** (balanced, cost-effective):
- **scaffolder** - Pattern-following implementation work
- **test-engineer** - Test pattern matching and writing
- **optimizer** - Code analysis and straightforward refactoring
- **documenter** - Documentation synthesis

### Delegation Capabilities

**Can delegate to other agents** (has Task tool):
- **reviewer** → scaffolder (delegates fixes)
- **implementation-planner** → scaffolder (delegates branch implementation)
- **gap-finder** → scaffolder (delegates missing implementations)
- **optimizer** → scaffolder (delegates major refactoring)
- **documenter** → notion-sync (delegates Notion updates)

**Executor agents** (no delegation):
- scaffolder, test-engineer, integration-tester, plan-keeper, notion-sync

## Agent Workflow

```
┌─────────────┐
│   PLANNING  │  implementation-planner → plan-keeper
└─────────────┘
       ↓
┌─────────────┐
│    BUILD    │  scaffolder → test-engineer
└─────────────┘
       ↓
┌─────────────┐
│   QUALITY   │  gap-finder → integration-tester → reviewer
└─────────────┘
       ↓
┌─────────────┐
│   POLISH    │  optimizer → documenter → notion-sync
└─────────────┘
```

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

## How It Works

### Agents are Tools, Not Requirements
Claude Code chooses to use these agents when appropriate for the task. There's no guarantee any particular agent will be invoked.

### Each Agent Has One Job
The scaffolder writes code. The test-engineer writes tests. The reviewer reviews. Single responsibility makes them reliable.

### Clean Context Every Time
Each agent starts with zero context and must discover what it needs—no hidden state, no assumptions. This means predictable behavior.

### They Know Your Codebase
All agents reference the `.knowledge` directory for Babylist-specific patterns. When the scaffolder runs, it checks `.knowledge/conventions/route-placement.md` for route placement conventions.

### They Fail Gracefully
Agents distinguish between issues they can fix (missing files, flaky tests) and issues that need human intervention (fundamental bugs, missing requirements). When blocked, they report partial progress and what's needed to continue.

## Usage

Agents are invoked automatically by Claude Code based on task context. Examples:

```bash
# Simple feature - likely triggers: scaffolder → test-engineer → reviewer
"Implement a new affiliate partner integration for PartnerX"

# Complex feature with plan - likely triggers: implementation-planner → scaffolder → gap-finder → reviewer
"Plan and implement multi-step checkout flow (Notion: [link])"

# Bug fix - likely triggers: gap-finder → scaffolder → test-engineer → reviewer
"Fix payment processing edge case where..."

# Refactoring - likely triggers: optimizer → scaffolder → test-engineer → reviewer
"Consolidate duplicate service classes in payment module"
```

## Project Context

These agents are configured for the [Babylist](https://www.babylist.com) codebase and reference patterns from the `.knowledge` directory for:
- Route placement conventions
- URL generation with Rails helpers
- Component export patterns
- Database migration management
- Service class consolidation
- Event subscription patterns
- Testing patterns (journey tests, N+1 detection, VCR)

## Repository Structure

```
.claude/
├── agents/              # Agent configuration files
│   ├── scaffolder.md
│   ├── test-engineer.md
│   ├── reviewer.md
│   ├── optimizer.md
│   ├── documenter.md
│   ├── integration-tester.md
│   ├── gap-finder.md
│   ├── implementation-planner.md
│   ├── plan-keeper.md
│   └── notion-sync.md
└── README.md            # This file
```

## Links

- [Notion Documentation](https://www.notion.so/2816928bf6f1809a8e5fe9aa9e84fe73) - Full agent system documentation
- [Claude Code](https://claude.ai/code) - Official Claude Code CLI

## License

Personal configuration - not licensed for public use.
