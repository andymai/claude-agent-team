---
description: GitHub contribution summaries for performance reviews
memory: local
---

Generate a contribution summary from GitHub PR data for performance reviews.

## Process

Parse from: {{RAW_PROMPT}} — accepts natural time periods (current month default, or "Q4 2024", "past 6 months", "since October", "H1 2025", etc.). Supports `--repo=org/repo`, `--username=USER`, `--local-only`, `--force`.

Auto-detect repo from `git remote get-url origin` and username from `git config user.github` if not provided.

For multi-month periods, generate one report per month chronologically.

## Data Collection

Fetch authored PRs via `gh pr list --repo REPO --author=USER --search "created:START..END" --state=all --limit=1000 --json number,title,state,url,createdAt,mergedAt,additions,deletions,files,labels,body`.

Fetch reviewed PRs via `gh api graphql` searching `reviewed-by:USER -author:USER created:START..END`, paginating until complete.

## Report Structure

Lead with **business impact**, not PR count. Categorize PRs (features, infrastructure, bug fixes, performance, refactoring, tech debt, testing, docs) and group by project area (infer from CODEOWNERS, directory structure, or pack names).

Format: Executive Summary (5-7 impact-focused bullets) → Key Accomplishments (goal/contribution/impact per project) → Contributions by Area (PRs grouped by type with links) → Code Reviews.

Use YAML frontmatter with repo, user, period, stats, and areas.

## Storage

Save to `.contribution-reports/REPO_NAME/YYYY/months/MM-monthname.md`. Unless `--local-only`, upload to `USERNAME/contribution-reports` private repo on GitHub (create if needed via `gh repo create`), then delete local copy.

Remember the repo's area mappings, PR body conventions, and common project themes in your memory.
