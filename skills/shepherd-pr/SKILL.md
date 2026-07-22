---
name: shepherd-pr
description: >
  Drive the current branch's pull request to a fully clean state — every review
  comment resolved, every check-run green (including neutral-status reviewers
  that the CI rollup hides), and CI passing — running as an autonomous loop, then
  hand the PR back. Use when the user says "shepherd the PR", "drive this PR to
  green", "clean up the PR", "address comments and get CI green", or similar.
  Portable across any GitHub repo (plain git or Graphite).
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob]
---

# Shepherd PR

Take the current branch's PR to a clean state — no unresolved comments, no open
check-run findings, and passing CI — as an autonomous loop, then report and hand
it back. This is repo-agnostic: it detects Graphite vs plain git and derives the
GitHub login at runtime, so it works across any personal repo.

## Step 0 — Detect the environment (once)

```bash
gh pr view --json number,url,title,assignees,state,isDraft,headRefName,baseRefName
gh repo view --json owner,name
ME=$(gh api user -q .login)
# Push strategy: Graphite only if it actually tracks this branch, else plain git.
if command -v gt >/dev/null && gt branch info >/dev/null 2>&1; then PUSH="gt submit"; else PUSH="git push"; fi
```

If no PR is found, stop and report. If `state` is `CLOSED` or `MERGED`, stop —
there's nothing to shepherd. A draft PR is fine to shepherd; **record the starting
`isDraft` value** so Step 3 can restore it if something demotes the PR mid-loop.

If the user is currently in `assignees`, unassign so notifications stay quiet
during the loop (skip if not assigned — common in solo repos):

```bash
gh pr edit {number} --remove-assignee "$ME"
```

## Step 1 — The loop

Repeat 1a–1e until the exit condition (1e) holds.

### 1a — Fetch review threads AND top-level review bodies

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved path line
          comments(first: 20) { nodes { id author { login } body createdAt } }
        }
      }
      reviews(first: 50) { nodes { id author { login } body state submittedAt } }
    }
  }
}' -f owner='{owner}' -f repo='{repo}' -F pr={number}
```

Check `reviews[].body` too, not just `reviewThreads` — a reviewer can leave a real
directive as the top-level review body, which the threads query misses entirely.
There's no thread to resolve for a top-level body, so acknowledge it in the Step 3
summary instead.

Filter to unresolved threads. Classify each:

- **Aside** — body starts with `aside` or `(aside)` (case-insensitive). Skip entirely: no fix, no reply, no resolve.
- **Actionable** — a real issue or sensible change request. Fix it.
- **Disagree** — the suggestion is wrong or unnecessary. Reply with respectful reasoning; leave the thread open.
- **Question** — asking, not requesting a change. Reply with the answer.

Tag each author **bot** (login contains `[bot]`, or `github-actions`, `codecov`,
`coderabbitai`, `cubic`, `rubocop-challenger`, `danger`, `linear`) or **human**.

### 1b — Sweep check-runs by SHA (catches neutral-status findings)

Some reviewers report findings as GitHub **check-runs with a `neutral` conclusion**,
not as `failure` — so `gh pr checks` / `statusCheckRollup` reports the PR green while
findings are still open. Query check-runs against the head SHA directly:

```bash
SHA=$(gh pr view {number} --json headRefOid -q .headRefOid)
gh api repos/{owner}/{repo}/commits/$SHA/check-runs --jq '
  .check_runs[] | select(.conclusion=="neutral" or .conclusion=="action_required") |
  {name, conclusion, title: .output.title, summary: .output.summary}'
```

A check is **clean** when its title is `"No issues"` / `"Skipped"` (or the check
isn't in the list above). A check has a **finding** when its title names a count
(e.g. `"2 issues"`). Parse `summary` into individual findings and classify each the
same way as a review comment. These have no thread — remediate in 1c, and note any
you refute in the Step 3 summary.

### 1c — Fix, reply, resolve

For each actionable item (comment or check-run finding):
1. Read the file at the referenced path/line and understand the full context.
2. Make the **minimal** fix that addresses exactly what was raised.
3. Reply confirming (check-run findings have no thread — skip the reply; the fix speaks once the check re-runs).

Reply to a thread:

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { id }
  }
}' -f threadId='{threadId}' -f body='{reply}'
```

Reply style: **Fixed** → one-line confirmation; **Disagree** → clear, respectful
reasoning citing code/tests/docs; **Question** → direct answer. Sign each reply
`— claude`.

Resolve a thread only when the author is **human** AND you made a fix or answered
fully. Do **not** resolve disagreements (leave for the reviewer) or bot threads
(they auto-resolve on the next push):

```bash
gh api graphql -f query='
mutation($threadId: ID!) { resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } } }' \
  -f threadId='{threadId}'
```

### 1d — Commit, push, monitor CI

If any files changed:

```bash
git add -A && git commit -m "Address PR review comments"
$PUSH   # gt submit or git push, per Step 0; use `git push -u origin HEAD` if no upstream
```

Watch CI to completion (portable, no external script):

```bash
gh pr checks {number} --watch --fail-fast; echo "exit=$?"
```

- **exit 0** — CI green. Proceed to the exit check.
- **exit non-zero** — a check failed. Rule out flakiness first: if the failure is an
  isolated test unrelated to this diff, `gh run rerun --failed` once. If it fails the
  same way again, treat it as real — read the failed check, fix, verify locally,
  commit, push, and watch again. Repeat until green.

### 1e — Exit condition

Done when **all three** hold, re-checked against the latest head SHA:
1. No unresolved comments (re-run 1a — new comments may have arrived during CI).
2. No open check-run findings (re-run 1b — a green `gh pr checks` does **not** imply
   the neutral-status checks are clean).
3. CI green (the most recent watch exited 0).

If any regressed, go back to 1a (new comments/findings) or 1d (a fix broke CI).

## Step 2 — Re-verify state before handing back

```bash
gh pr view {number} --json state,headRefOid,isDraft
```

If `state` is no longer `OPEN`, stop and report — don't touch a PR closed/merged
mid-loop. If `headRefOid` moved past the SHA CI last saw green (a late commit
landed), go back to Step 1a. If the PR started ready (`isDraft: false`) but is now
draft and all findings are clear, restore it — `gh pr ready {number}` — but never
override a draft the user set deliberately.

## Step 3 — Reassign and report

Re-add the user as assignee only if you unassigned them in Step 0:

```bash
gh pr edit {number} --add-assignee "$ME"
```

Check the description against the final diff (`gh pr view {number} --json body` vs
`git diff {baseRef}...HEAD --stat`) and update it **only** if the loop's changes made
it inaccurate. Keep edits surgical; a terse-but-correct description stays as-is.

Print a summary:

```
## PR #{number} — shepherded to clean state

**Comments**: X fixed, Y replied, Z skipped (aside); top-level review bodies: N handled
**Check-run findings**: X fixed, Y refuted (reasons), or "clean"
**Draft state**: unchanged | restored to ready
**Description**: updated to reflect <change> | left as-is (accurate)
**CI cycles**: N (list any failures fixed)
**Status**: ✓ Comments resolved, checks clean, CI green — reassigned to @{me}
```
