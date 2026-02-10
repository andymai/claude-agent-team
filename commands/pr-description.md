---
description: Generate a PR title and description from branch changes
memory: user
---

Generate a pull request title and description from the current branch.

## Process

Parse from: {{RAW_PROMPT}} — supports `--base=BRANCH`, `--draft`, `--verbose`.

Detect base branch (`git remote show origin | grep 'HEAD branch'` if not specified). Get all commits and the full diff against base. Analyze what changed, why, and classify the change type.

## Output

Print a conventional commit title (`type: description`, imperative mood, under 72 chars) and a description with: Summary (2-3 sentences on what and why), Changes (bullet per logical change), Testing (how to verify), and Notes (optional: tradeoffs, follow-ups). Add a file-by-file table if `--verbose`. Use shorter Summary + TODO checklist format if `--draft`.

Do not create the PR — just print the content for the user to copy or pipe to `gh pr create`.

Remember the repo's PR conventions (title style, description sections, common labels) in your memory for future runs.
