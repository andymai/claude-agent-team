---
description: Create a conventional commit from working tree changes
memory: local
---

Stage and commit working tree changes as a Conventional Commit.

## Process

Parse from: {{RAW_PROMPT}} — supports `--type=TYPE`, `--scope=SCOPE`, `--breaking`, `--dry-run`.

Run `git status` and `git diff` (and `git diff --cached` for already-staged work) in parallel. Inspect what changed and classify each logical change.

If the working tree contains multiple unrelated changes, surface them as a numbered list and ask whether to bundle into one commit or split across several. For splits, stage subsets explicitly per commit.

Stage files by name — never `git add -A` or `git add .`. Skip files that look like secrets (`.env`, credentials, keys, tokens), large binaries, or build artifacts; warn if the user has staged them already.

Compose the message:

- **Type** (required): one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Pick from the diff, not the filename.
- **Scope** (optional): a short noun in parentheses — module, package, or area. Use scopes you've seen in recent `git log` for this repo when they fit.
- **Breaking changes**: append `!` after type/scope (`feat(api)!: …`) and add a `BREAKING CHANGE:` footer explaining the migration. Set when `--breaking` is passed or the diff removes/renames public surface.
- **Subject**: imperative mood, lowercase first letter, no trailing period, under 72 chars total including the prefix.
- **Body** (when non-trivial): wrap at 72 cols, focus on *why* and tradeoffs, not *what* — the diff shows what.
- **Footer** (optional): `Refs: #123`, `Closes #456`, `BREAKING CHANGE: …`.

Show the proposed message before committing. On `--dry-run`, stop here.

Run the commit with a HEREDOC so multi-line messages format correctly:

```
git commit -m "$(cat <<'EOF'
type(scope): subject

body

footer
EOF
)"
```

## On hook failure

If a pre-commit hook fails, surface the hook output, attempt the obvious fix (re-run linter/formatter, re-stage modified files), then create a **new** commit. Never use `--amend` (the original commit didn't happen — amending would rewrite the previous one) and never `--no-verify`.

## After commit

Run `git status` to confirm. Print the new commit hash and subject line.

Remember this repo's scope vocabulary, common types, and message-body style in your memory for future runs. If CLAUDE.md or a `.gitmessage` template specifies conventions, follow those over defaults.
