---
description: GitHub contribution summaries for performance reviews
---

# Contribution Report

Generate a comprehensive summary of your GitHub contributions for performance tracking.

## Usage

Use natural language to specify the time period:

- `/contribution-report` - Current month (default)
- `/contribution-report Q4 2024` - Quarter, month, year, or half-year
- `/contribution-report past 6 months` - Rolling window
- `/contribution-report since October` - Open-ended range

### Options

- `--repo=org/repo` - Repository (default: auto-detect from git remote)
- `--username=otheruser` - Different GitHub username (skips upload)
- `--local-only` - Save locally only, skip GitHub upload
- `--force` - Regenerate even if summary already exists in repo

## Task

### 1. Parse Arguments & Setup

Extract the time period from: {{RAW_PROMPT}}

**Time period patterns** (use current date as reference):

| Input Pattern | Interpretation |
|--------------|----------------|
| _(empty)_ | Current month |
| `October 2025`, `Oct 2025`, `2025-10` | Specific month |
| `past N months`, `last N months` | Rolling N months ending now |
| `last quarter`, `previous quarter` | Previous calendar quarter |
| `this quarter`, `current quarter`, `Q1 2025` | Specific quarter (Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec) |
| `H1 2025`, `H2 2025` | Half-year (H1=Jan-Jun, H2=Jul-Dec) |
| `this year`, `2025`, `ytd` | Full/partial calendar year |
| `January to March 2025` | Custom month range |
| `since October` | From that month to current month |

**Repository:** Use `--repo` if provided, otherwise auto-detect:
```bash
git remote get-url origin | sed -E 's/.*github.com[:/]([^/]+\/[^/.]+)(\.git)?$/\1/'
```
Store as `REPO_FULL` (e.g., `acme/web`) and `REPO_NAME` (e.g., `acme-web` for paths).

**GitHub username:** Use `--username` if provided, otherwise `git config user.github`. Ask user if empty.

**Date range:** START_DATE and END_DATE in YYYY-MM-DD format.

**Output path:** `[REPO_NAME]/YYYY/months/MM-monthname.md`

### 1b. Batch Multi-Month Periods

For periods spanning multiple months (YTD, quarters, half-years, rolling windows, custom ranges, or "since X"):

1. Calculate all complete months in the range (exclude partial current month)
2. For each month, run Steps 2-8 with that month's date range
3. Process chronologically, skip existing reports unless `--force`
4. On completion: print summary with URLs for all generated reports

**Single-month periods proceed directly to Step 2.**

### 2. Check for Existing Summary

**Skip if:** `--force`, `--local-only`, or `--username` is set.

```bash
gh api repos/USERNAME/contribution-reports/contents/[OUTPUT_PATH] --silent 2>/dev/null
```

If exists: print URL and `Use --force to regenerate`, then stop.

### 3. Fetch PR Data

Use `REPO_FULL` for all API calls.

**PRs authored:**
```bash
gh pr list --repo [REPO_FULL] --author=USERNAME --search "created:START_DATE..END_DATE" --state=all --limit=1000 --json number,title,state,url,createdAt,mergedAt,additions,deletions,files,labels,body
```

**PRs reviewed (paginate until `hasNextPage=false`):**
```bash
gh api graphql -f query='
{
  search(query: "repo:[REPO_FULL] reviewed-by:USERNAME -author:USERNAME created:START_DATE..END_DATE", type: ISSUE, first: 100, after: CURSOR_OR_NULL) {
    pageInfo { hasNextPage, endCursor }
    edges { node { ... on PullRequest { number, title, url, state, createdAt, reviews(first: 100, author: "USERNAME") { nodes { createdAt, state } } } } }
  }
}'
```

### 4. Analyze PRs

#### 4a. Extract Business Context from PR Body

Parse for:
- `## Why` / `## What` sections
- JIRA tickets: `PROJ-123`, `babylist.atlassian.net/browse/PROJ-123`
- Notion links

**Business impact keywords:** conversion, revenue, checkout, UX, performance, load time, cleanup, deprecate, technical debt, fix, bug, crash, optimization, cache, latency

#### 4b. Identify Project Area

1. Check `.github/CODEOWNERS` first
2. For monorepos: use pack names (e.g., `packs/storefront` -> Storefront)
3. Directory patterns: `store/checkout/cart/` -> Commerce, `registry/` -> Consumer, `fulfillment/` -> Fulfillment, `admin/` -> Admin, `db/migrate/` -> Database

#### 4c. Categorize by Type (priority order)

1. **Features** ✨: New functionality, "add", "implement", experiments
2. **Infrastructure** 🔧: API upgrades, architecture, CI/CD - HIGH VALUE
3. **Bug Fixes** 🐛: Production/user-facing fixes
4. **Performance** 🚀: Optimizations, caching
5. **Refactoring** ♻️: Code improvements without behavior change
6. **Technical Debt** 🧹: Feature flag cleanup, dead code removal - SUPPORTING work
7. **Testing** 🧪: Test additions
8. **Documentation** 📝

### 5. Research Context (Optional)

For major PRs: search `.knowledge/`, check for ADRs, look for related PRs.

### 6. Generate Report

**Prioritization rules:**
- Lead with IMPACT, not count - one major feature > multiple small cleanups
- Features and infrastructure come FIRST
- Production bug fixes are accomplishments
- Feature flag cleanup goes LAST under "Technical Debt"
- 500+ line PRs deserve more coverage

```markdown
---
repo: org/repo
user: github_username
period: 2025-11
stats: { authored: X, merged: Y, reviewed: Z, +lines: N, -lines: N }
areas: [Area1, Area2, Area3]
---

# Contribution Report - [REPO_NAME] - [Period Description]

## Executive Summary

5-7 bullets with BUSINESS IMPACT first. Format:
- **[Theme/Project]**: [Business outcome]. [Technical contribution]. [Tickets]

Example:
- **Shopify API Upgrade**: Upgraded from 2024-10 to 2025-07 for platform compatibility. Major infrastructure investment.
- **PDP Recommendations**: Built product recommendations experiment for data-driven product discovery.
- **Registry Bug Fixes**: Fixed purchased items disappearing and reservation cart cleanup. Restored correct gift-giver behavior.
- **Technical Debt**: Removed 7 stale feature flags, reducing costs and complexity.

## Key Accomplishments

### [Project/Theme Name]
**Goal**: Business objective
**Contribution**: What you built/fixed
**Impact**: Result (metrics, user impact, cost savings)
PRs: #123, #456

## Contributions by Area

### [Area] (X PRs)

#### Features ✨
- **[#123 - Title](URL)** ✅ - Why: [business reason] | What: [technical summary] | Tickets: PROJ-123

#### Infrastructure 🔧
- **[#456 - Upgrade API](URL)** ✅ - Impact: [description]

#### Bug Fixes 🐛
- **[#789 - Fix timeout](URL)** ✅ - Impact: [P1 resolution] | Root cause: [explanation]

#### Technical Debt 🧹
- **[#999 - Remove flag](URL)** ✅ - Flag at 100% for 3 months

## Code Reviews 👀

Reviewed X PRs. Notable:
- **[#789 - Title](URL)** - [Your contribution: caught bug, suggested optimization]

---
_Generated on [Date] using /contribution-report_
```

### 7. Save Locally

Save to `.contribution-reports/[OUTPUT_PATH]`, creating directories as needed (upsert).

### 8. Upload to GitHub

**Skip upload if:** `--local-only` OR `--username` specifies different user.

```bash
# Create repo if needed
gh repo view USERNAME/contribution-reports >/dev/null 2>&1 || \
  gh repo create USERNAME/contribution-reports --private

# Clone/update and push
[ -d "/tmp/contribution-reports" ] && (cd /tmp/contribution-reports && git pull) || \
  gh repo clone USERNAME/contribution-reports /tmp/contribution-reports

mkdir -p /tmp/contribution-reports/$(dirname [OUTPUT_PATH])
cp .contribution-reports/[OUTPUT_PATH] /tmp/contribution-reports/[OUTPUT_PATH]
cd /tmp/contribution-reports && git add [OUTPUT_PATH] && \
  git commit -m "Add/Update [REPO_NAME] summary for [PERIOD_DESCRIPTION]" && \
  git push origin main
```

**Success:** Delete local file, print upload URL.
**Failure:** Keep local file, print error and local path.

## Notes

- Status emojis: ✅ MERGED, 🔄 OPEN, ❌ CLOSED
- If no PRs found, create report indicating no activity
- Scale executive summary length for longer periods
