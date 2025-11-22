# Contribution Report

Generate a comprehensive summary of your GitHub contributions for performance tracking.

## Usage

Use natural language to specify the time period:

- `/contribution-report` - Current month (default)
- `/contribution-report Q4 2024` - Quarter, month, year, or half-year
- `/contribution-report past 6 months` - Rolling window
- `/contribution-report since October` - Open-ended range

See parsing table below for all supported formats.

### Options

- `--repo=org/repo` - Repository (default: auto-detect from git remote)
- `--username=otheruser` - Different GitHub username (skips upload)
- `--local-only` - Save locally only, skip GitHub upload
- `--force` - Regenerate even if summary already exists in repo

## Task

You are tasked with creating a contribution report. Follow these steps:

### 1. Parse Arguments & Setup

Extract the time period from the natural language input:
{{RAW_PROMPT}}

**Parse the time period** using these patterns (today's date for reference: use current date):

| Input Pattern | Interpretation |
|--------------|----------------|
| _(empty)_ | Current month |
| `October 2025`, `Oct 2025`, `2025-10` | Specific month |
| `past N months`, `last N months` | Rolling N months ending now |
| `last quarter`, `previous quarter` | Previous calendar quarter |
| `this quarter`, `current quarter` | Current calendar quarter |
| `Q1 2025`, `Q2`, etc. | Specific quarter (Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec) |
| `H1 2025`, `H2 2025` | Half-year (H1=Jan-Jun, H2=Jul-Dec) |
| `this year`, `2025` | Full calendar year |
| `year to date`, `ytd` | January 1 of current year to now |
| `January to March 2025` | Custom month range |
| `since October`, `since Oct 2025` | From that month to current month |

**Determine target repository:**
- If `--repo` provided, use that value (e.g., `acme/api`)
- Otherwise, auto-detect from current git remote:
  ```bash
  git remote get-url origin | sed -E 's/.*github.com[:/]([^/]+\/[^/.]+)(\.git)?$/\1/'
  ```
- Store as `REPO_FULL` (e.g., `acme/web`) and `REPO_NAME` (e.g., `acme-web` for paths)

**Get GitHub username:**
- If `--username` not provided, get from: `git config user.github`
- If git config is empty, ask the user for their GitHub username

**Calculate date range:**
- START_DATE: First day of the starting period (format: YYYY-MM-DD)
- END_DATE: Last day of the ending period (format: YYYY-MM-DD)

**Determine output path:**

Paths prefixed with `[REPO_NAME]/` (repo with `/` → `-`, e.g., `acme-web/`):

| Period | Path |
|--------|------|
| Month | `YYYY/months/MM-monthname.md` |
| Quarter | Batched into monthly reports |
| Half-year | Batched into monthly reports |
| Full year | Batched into monthly reports |
| YTD | Batched into monthly reports |
| Rolling/Custom | Batched into monthly reports |

### 1b. Batch Multi-Month Periods

**For periods spanning multiple months** (YTD, quarters, half-years, full years, rolling windows, custom ranges, or "since X"):

Instead of generating one combined report, **batch the request into individual monthly reports**. This provides more granular tracking and avoids overly large reports.

**How to batch:**
1. Calculate all complete months in the date range (exclude partial current month if still in progress)
2. For each month, recursively run the full report generation process (Steps 2-8) with:
   - `START_DATE`: First day of that month
   - `END_DATE`: Last day of that month
   - `OUTPUT_PATH`: `YYYY/months/MM-monthname.md` (e.g., `2025/months/01-january.md`)
3. Process months in chronological order
4. Skip months that already have reports (unless `--force` is set)

**Example:** For `ytd` run on November 15, 2025:
- Generate reports for: January, February, March, April, May, June, July, August, September, October (10 reports)
- Skip November (current/partial month)
- Each saved to: `babylist-web/2025/months/01-january.md`, `babylist-web/2025/months/02-february.md`, etc.

**After all monthly reports are generated:**
- Print summary: `✅ Generated X monthly reports for [PERIOD_DESCRIPTION]`
- List each report URL

**Single-month periods** (e.g., `October 2025`, `2025-10`, or empty/current month) do NOT batch - proceed directly to Step 2.

### 2. Check for Existing Summary

**Skip this check if:** `--force`, `--local-only`, or `--username` (different user) is set.

Otherwise, check if summary already exists in the repo:
```bash
gh api repos/USERNAME/contribution-reports/contents/[OUTPUT_PATH] --silent 2>/dev/null
```

**If file exists:**
- Print: `ℹ️ Summary already exists: https://github.com/USERNAME/contribution-reports/blob/main/[OUTPUT_PATH]`
- Print: `Use --force to regenerate`
- **Stop** - do not proceed

**If file does not exist:** Continue to next step.

### 3. Fetch PR Data

Use `REPO_FULL` (e.g., `acme/web`) from Step 1 for all API calls.

**PRs authored:**
```bash
gh pr list --repo [REPO_FULL] --author=USERNAME --search "created:START_DATE..END_DATE" --state=all --limit=1000 --json number,title,state,url,createdAt,mergedAt,additions,deletions,files,labels,body
```

**PRs reviewed (with cursor pagination):**

Paginate until `hasNextPage=false`, using `endCursor` as `after` param:
```bash
gh api graphql -f query='
{
  search(query: "repo:[REPO_FULL] reviewed-by:USERNAME -author:USERNAME created:START_DATE..END_DATE", type: ISSUE, first: 100, after: CURSOR_OR_NULL) {
    pageInfo { hasNextPage, endCursor }
    edges { node { ... on PullRequest { number, title, url, state, createdAt, reviews(first: 100, author: "USERNAME") { nodes { createdAt, state } } } } }
  }
}'
```
Loop while `hasNextPage=true`, combining results. Filter to reviews within date range.

### 4. Analyze PRs

For each authored PR, extract structured information:

#### 4a. Extract Business Context from PR Body

Parse the PR body to extract:

1. **"Why" Section**: Look for `## Why` header and extract the explanation. This often contains business justification.
2. **"What" Section**: Look for `## What` header for the implementation summary.
3. **Linked Tickets**: Extract JIRA tickets (patterns: `PROJ-123`, `babylist.atlassian.net/browse/PROJ-123`)
4. **Notion Links**: Extract any Notion page references for additional context

**Business Impact Indicators** - Look for keywords:
- Revenue/conversion: "conversion", "revenue", "sales", "checkout", "purchase"
- User experience: "UX", "performance", "load time", "user experience"
- Technical debt: "cleanup", "remove", "deprecate", "technical debt", "feature flag"
- Reliability: "fix", "bug", "error", "crash", "stability"
- Scale: "optimization", "performance", "cache", "latency"

#### 4b. Identify Project Area

Use file paths to determine project area:

1. **Check CODEOWNERS first**: Fetch `.github/CODEOWNERS` and parse ownership rules
2. **Pack-based structure**: For monorepos with `packs/`, use pack names (e.g., `packs/storefront` → Storefront)
3. **Directory patterns**:
   - `store/`, `checkout/`, `cart/` → Commerce
   - `registry/`, `reg_item/` → Consumer/Registry
   - `fulfillment/`, `shipping/` → Fulfillment
   - `admin/` → Admin Tools
   - `db/migrate/` → Database
   - Design system paths → Design System

#### 4c. Categorize by Type

- **Features** ✨: New functionality, enhancements, "add", "implement", "create"
- **Feature Flag Cleanup** 🧹: "remove feature flag", technical debt reduction
- **Bug Fixes** 🐛: "fix", "bug", "🐛" in title
- **Refactoring** ♻️: "refactor", code improvements without behavior change
- **Infrastructure** 🔧: CI/CD, configs, tooling
- **Testing** 🧪: Test additions/improvements
- **Documentation** 📝: Docs, comments, README

### 5. Research Context (Optional)

For major PRs or those with linked tickets:

- Search `.knowledge/` directory for related documentation
- Look for ADRs (Architecture Decision Records) if mentioned
- Check if there are related PRs mentioned in the description

### 6. Generate Report

Create a comprehensive markdown report **optimized for performance reviews**. The goal is to make it easy to copy-paste accomplishments into review documents.

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

**This section is the most important for performance reviews.** Write 5-7 bullets that:
- Lead with BUSINESS IMPACT, not technical details
- Use active voice and quantify where possible
- Group related work into themes/projects
- Highlight cross-functional collaboration

Format:
- **[Theme/Project Name]**: [Business outcome]. [Technical contribution]. [Tickets if relevant]

Example bullets:
- **Registry Discount Rollout**: Enabled multi-use discount codes for 100% of users, completing the final rollout phase. Removed 3 feature flags and simplified discount logic. [SHOP-1679]
- **Store Performance**: Improved Product Listing Page load times by migrating to SPA architecture. Removed legacy rendering paths (-1,200 lines).
- **Technical Debt Reduction**: Removed 8 stale feature flags, reducing codebase complexity and LaunchDarkly costs.
- **Code Reviews**: Provided thorough reviews on 15 PRs across Commerce and Consumer teams, catching 3 potential bugs before production.

## Key Accomplishments

For each major project/theme, provide a 2-3 sentence narrative:

### [Project/Theme Name]

**Goal**: What was the business objective?
**Contribution**: What did you build/fix/improve?
**Impact**: What was the result? (metrics, user impact, cost savings, etc.)

PRs: #123, #456, #789

## Contributions by Area

### [Project Area 1] (X PRs)

#### Features ✨

- **[#123 - PR Title](PR_URL)** ✅
  - **Why**: [Extract from PR body - business reason]
  - **What**: [Brief technical summary]
  - Tickets: PROJ-123

#### Feature Flag Cleanup 🧹

- **[#456 - Remove XYZ feature flag](PR_URL)** ✅
  - Flag was at 100% for 3 months, safe to remove
  - Reduces LaunchDarkly complexity

#### Bug Fixes 🐛

- **[#789 - Fix checkout timeout](PR_URL)** ✅
  - **Impact**: Resolved P1 issue affecting 5% of checkouts
  - Root cause: N+1 query in cart validation

### [Project Area 2] (X PRs)

[Same structure]

## Code Reviews 👀

Summary: Reviewed X PRs this month

Notable reviews:
- **[#789 - PR Title](PR_URL)** - [Your contribution: caught bug, suggested optimization, etc.]

---

_Generated on [Date] using /contribution-report_
```

**Writing Guidelines for Executive Summary:**

1. **Start with outcomes, not activities**: "Improved checkout conversion by 2%" not "Updated checkout flow"
2. **Group related PRs**: If you made 5 PRs for one feature, summarize as one accomplishment
3. **Quantify when possible**: Lines removed, flags cleaned up, bugs fixed, PRs reviewed
4. **Mention collaboration**: "Worked with Design team on...", "Supported Fulfillment team by..."
5. **Highlight scope/complexity**: "Touched 15 files across 3 services", "Required coordination with mobile team"

### 7. Save Locally

- Create necessary subdirectories based on OUTPUT_PATH (e.g., `.contribution-reports/acme-web/2025/months/`)
- Save the report to: `.contribution-reports/[OUTPUT_PATH]` (path from Step 1)
- This overwrites any existing file at that path (upsert behavior)

### 8. Upload to GitHub (Default)

**Skip upload if ANY of these conditions are true:**
- `--local-only` flag IS provided
- `--username` flag specifies a different user (generating report for someone else)

If skipping upload:
- Print: `✅ Summary saved to: .contribution-reports/[OUTPUT_PATH]`
- If username differs: `ℹ️ Skipping GitHub upload (report is for different user: USERNAME)`

**If uploading:**

```bash
# 1. Create repo if needed
gh repo view USERNAME/contribution-reports >/dev/null 2>&1 || \
  gh repo create USERNAME/contribution-reports --private

# 2. Clone/update local copy
[ -d "/tmp/contribution-reports" ] && (cd /tmp/contribution-reports && git pull) || \
  gh repo clone USERNAME/contribution-reports /tmp/contribution-reports

# 3. Copy and push
mkdir -p /tmp/contribution-reports/$(dirname [OUTPUT_PATH])
cp .contribution-reports/[OUTPUT_PATH] /tmp/contribution-reports/[OUTPUT_PATH]
cd /tmp/contribution-reports && git add [OUTPUT_PATH] && \
  git commit -m "Add/Update [REPO_NAME] summary for [PERIOD_DESCRIPTION]" && \
  git push origin main
```

**On success:** Delete local file, print: `✅ Summary uploaded to: https://github.com/USERNAME/contribution-reports/blob/main/[OUTPUT_PATH]`

**On failure:** Keep local file, print: `⚠️ Upload failed. Saved locally to: .contribution-reports/[OUTPUT_PATH]`

## Notes

- Status emojis: ✅ MERGED, 🔄 OPEN, ❌ CLOSED
- Focus on **business value**, not just technical tasks
- Scale executive summary for longer periods
- If no PRs found, create report indicating no activity
- On upload failure: keep local file, explain error, print path

## Performance Review Tips

The generated reports should make it easy to:

1. **Identify themes**: Group PRs into 3-5 major themes per quarter (e.g., "Registry Discount Rollout", "Technical Debt Reduction")
2. **Quantify impact**: Use metrics like:
   - Lines of code added/removed
   - Number of feature flags cleaned up
   - Number of bugs fixed
   - PRs reviewed
   - Services/components touched
3. **Show growth**: Highlight new areas you contributed to, increased scope, or mentorship
4. **Document collaboration**: Note cross-team work, code reviews given, and knowledge sharing

When reading the report, look for:
- **Repeated project areas** = Your primary focus/expertise
- **Feature flag cleanup** = Technical debt ownership
- **Code reviews** = Team collaboration and mentorship
- **Large line counts** = Major features or refactoring efforts
- **Bug fixes** = Production reliability contributions
