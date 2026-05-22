---
description: Parse PR review feedback, triage by severity, and apply fixes as one commit per severity tier
memory: local
---

Respond to code review feedback on a pull request by invoking the `review-responder` agent.

## Process

Parse from: {{RAW_PROMPT}} — supports `<PR#>` (positional), `--dry-run`, `--no-reply` (skip posting thread replies), `--only=<tier>` (limit to one tier: `critical`, `important`, `nit`).

Resolve the target PR:

- If a PR number was passed, use it.
- Otherwise, look up the current branch's PR with `gh pr view --json number,headRefName,baseRefName`. If no PR is associated, surface that and ask whether to push and open one first.
- If the working tree has uncommitted changes, surface them and ask whether to stash, commit them under the current task, or abort — review-responder commits should land cleanly on top of the existing branch state.

Verify `gh` is available (`gh auth status`). If not, fall back to accepting raw review text pasted by the user.

Invoke the `review-responder` agent with:

- The resolved PR number (or raw review text).
- Any flags from `{{RAW_PROMPT}}` (`--dry-run`, `--no-reply`, `--only=…`).
- A brief note on what's been changed already in the branch, so the agent can detect any review item that's already been addressed in an unrelated commit.

The agent owns the full workflow: gather feedback → triage → plan commits → apply fixes → verify → reply on threads. Don't second-guess its commit grouping unless the user explicitly asked for a different shape.

## After the agent returns

Surface the agent's report: total findings, breakdown by tier, commit hashes, deferred/disputed items. If commits were created, show `git log --oneline` for the new ones so the user can confirm before pushing.

Do not push to remote automatically — the user pushes on their own cadence.

Remember in memory: per-project recurring review categories (e.g., this repo often gets flagged on missing variant coverage), which severity tiers tend to dominate, and any reviewer conventions worth pre-empting in future engineering passes.
