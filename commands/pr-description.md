---
description: Generate a PR title and description from branch changes
memory: local
---

Generate a pull request title and a structured description from the current branch.

## Process

Parse from: {{RAW_PROMPT}} — supports `--base=BRANCH`, `--draft`, `--verbose`, `--terse` (single-summary format), `--no-investigation` (skip the investigation-notes section even when applicable).

Detect base branch automatically (`git remote show origin | grep 'HEAD branch'`) if `--base` isn't passed. Pull every commit subject, body, and the full diff against base. Classify the overall change shape: bugfix (`fix:`), feature (`feat:`), refactor (`refactor:`), perf (`perf:`), chore (`chore:`), etc.

## Title

Conventional commit format: `type(scope): subject`, imperative mood, lowercase first letter, no trailing period, under 70 chars total. If the branch had a dominant scope across its commits, use it. If the branch crossed scopes, omit the scope or pick the highest-impact one.

## Description structure

The default template — used when the branch contains anything more than a one-line trivial change:

```
## Summary

<2-3 sentences. State what changed and the user-visible effect. Skip "we did X" — say what the code now does.>

## What changes

- **<section name>** — <one or two sentences explaining what and why for each logical bucket of change>
- **<section name>** — …

(Group by feature area, file family, or concern — not by commit. Bold the bucket name. One bullet per coherent unit of work; expand with sub-bullets only when the bucket has 3+ sub-units.)

## What does *not* change

- <explicit non-scope item — types, schemas, configs, behaviors that callers might worry about>
- <…>

(Include this section when the diff is non-trivial OR when callers might fear a wider impact than was made. Skip when the diff is tiny and self-evident. The point is to spare reviewers from re-reading code that didn't move.)

## Test plan

- [x] <automated check 1, e.g. `pnpm test` — 353 pass>
- [x] <automated check 2, e.g. `pnpm typecheck` clean>
- [x] <automated check 3 if relevant, e.g. `cargo clippy --all-targets -- -D warnings` clean>
- [ ] <manual verification step 1, phrased so a reviewer can actually do it>
- [ ] <manual verification step 2>

(Always include this section. `[x]` for what you ran locally with green results. `[ ]` for what needs a human or device the agent can't drive — visual smoke, real-device tests, etc.)
```

## Conditional sections

Add these only when the diff warrants them:

- **`## Investigation notes`** — for bug fixes where multiple hypotheses were ruled out, or when "what changed vs. what was already fine" needs a side-by-side table. Use a markdown table with columns like `Scenario | Behavior on main | Cause | This PR`. Shows reviewers your reasoning trail without burying it in commit messages.

- **`## Caveats up front`** — for large or risky PRs. Surface tooling limitations, missing test coverage you couldn't add, environment-specific differences, or work that landed differently than originally planned. Put it near the top so reviewers see it before they dig in.

- **`## Why not a full fix`** — for partial fixes. State the residual problem class, what you tried and reverted, and what the architecturally-correct fix would look like. Pairs well with linking a follow-up issue.

- **`## Impact`** — for performance or correctness work with measurable outcomes. Use a table with before/after numbers across scenarios. Don't claim a perf win without numbers.

- **`## Verification`** — a longer-form alternative to Test plan, used when the testing involved is itself a discussion (cross-platform, multi-device, end-to-end with external services). When you need this, omit Test plan to avoid duplication.

## Flag behavior

- `--draft` — emit Summary + a Test plan checklist of TODOs. Skip "What does not change" and conditional sections. Used for "open the PR now, write the rest later" mode.
- `--verbose` — add a file-by-file table at the bottom (path, +/- lines, one-line purpose).
- `--terse` — produce a single-paragraph summary with no headings. Use only when the diff is one-liner trivial; ask before emitting this for anything non-trivial.
- `--no-investigation` — even if the diff looks like a bug fix with hypothesis-testing, skip the Investigation notes section.

## Output

Print the title on one line, then the description. Do not create the PR — just output the content for the user to paste into `gh pr create` or the GitHub UI. If the description contains backticks, the user can pipe to `gh pr create --title "<title>" --body-file -` to avoid quoting issues.

## Inferring content

- "What changes" buckets: read commit subjects + diff hunk locations. If multiple commits touch the same area, merge them into one bullet. If a single commit spans areas, split it.
- "What does not change": find adjacent surfaces in the diff — types/interfaces near the changed files, sibling functions in the same module, callers of changed functions. If any of those would be a reasonable place for the change to bleed but didn't, name them as not-changed.
- "Test plan" automated items: scan the diff for changes to test files; mention them. Run the project's check command (`/check` convention) and report its output. If no test changes were made for a code change that should have them, mark a `[ ]` item explicitly: "needs test for X — followup".
- "Test plan" manual items: derive from the change surface. UI changes → "visual check at <route>". State changes → "<flow> end-to-end". Schema changes → "verify migration on staging".

Remember the repo's PR conventions in your memory: which sections it actually uses, how detailed the bullets get, which check commands its CI runs, scope vocabulary, and any project-specific sections (e.g., "Breaking changes", "Localization impact", "Migration notes") to include for future runs.
