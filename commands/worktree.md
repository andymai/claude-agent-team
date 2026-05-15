---
description: Set up a git worktree under .worktrees/ for parallel branch work
memory: local
---

Create a git worktree under `.worktrees/<branch>` so the user can work on a feature branch in parallel without disrupting the current working tree.

## Process

Parse from: {{RAW_PROMPT}} — supports `<branch-name>` (required), `--base=<base-branch>` (default: `main`), `--from=<existing-branch>` (check out existing instead of creating).

### 1. Sanity checks

- Confirm we're inside a git repo (`git rev-parse --git-dir`).
- Confirm the working tree is clean — if not, list dirty paths and ask whether to stash, commit, or abort. Don't proceed silently.
- Confirm `.worktrees/` is gitignored. If not, propose adding it to `.gitignore` first.
- If `.worktrees/<branch>` already exists, list it and stop — don't clobber.

### 2. Create the worktree

For a new branch:

```bash
git fetch origin
git worktree add -b <branch> .worktrees/<branch> origin/<base>
```

For an existing branch:

```bash
git worktree add .worktrees/<branch> <branch>
```

Use `git worktree list` to confirm it registered.

### 3. Post-setup hints

After creation, print:

- The new worktree path
- Whether dependencies need a re-install (check for `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, etc. in the new worktree — if any, suggest the install command)
- The command to enter it: `cd .worktrees/<branch>`

## Conventions

- `.worktrees/` is the canonical location. Do **not** use sibling-directory worktrees (e.g., `../foo-branch`) or `.claude/worktrees/`.
- Always run `gh pr merge` (and any branch-deleting command) from the **main repo path**, not from inside the worktree. The `--delete-branch` flag will pull the working dir out from under bash if invoked from the worktree.
- After a PR merges and the branch is deleted upstream: from the main repo, run `git worktree remove .worktrees/<branch>` to clean up.

## When Stuck

If `git worktree add` fails with "fatal: '<branch>' is already checked out at ...", the branch is open in another worktree. Show `git worktree list` and ask the user which worktree they want to use, or whether to detach the existing one.
