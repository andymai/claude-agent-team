---
description: Generate a PR title and description from branch changes
---

# PR Description

Generate a pull request title and description from your current branch changes.

## Usage

- `/pr-description` - Generate from staged/committed changes vs main
- `/pr-description --base=develop` - Compare against different base branch
- `/pr-description --draft` - Shorter description, mark as draft
- `/pr-description --verbose` - Include file-by-file breakdown

## Task

### 1. Gather Context

**Base branch:** Use `--base` if provided, otherwise detect default:
```bash
git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
```

**Current branch:**
```bash
git branch --show-current
```

**Commits on this branch:**
```bash
git log $(git merge-base HEAD origin/BASE_BRANCH)..HEAD --oneline
```

**Full diff:**
```bash
git diff origin/BASE_BRANCH...HEAD --stat
git diff origin/BASE_BRANCH...HEAD
```

### 2. Analyze Changes

Review the diff and commits to understand:
- **What** changed (files, functions, components)
- **Why** it changed (infer from commit messages, code context)
- **Type** of change: feature, fix, refactor, chore, docs

Look for:
- Breaking changes (API modifications, removed exports, schema changes)
- Test coverage (new tests added?)
- Migration requirements (database, config changes)

### 3. Generate Title

Format: `type: short description`

**Type prefixes:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructuring
- `chore:` - Maintenance, deps, tooling
- `docs:` - Documentation only
- `test:` - Test additions/changes
- `perf:` - Performance improvement

**Title rules:**
- Lowercase after prefix
- No period at end
- Under 72 characters
- Imperative mood ("add X" not "added X")

### 4. Generate Description

```markdown
## Summary

[2-3 sentences: what this PR does and why]

## Changes

- [Bullet point per logical change]
- [Group related file changes together]
- [Focus on what, not how]

## Testing

[How to verify this works - manual steps or test commands]

## Notes

[Optional: anything reviewers should know - tradeoffs, follow-ups, questions]
```

**If `--verbose`**, add after Changes:
```markdown
## Files Changed

| File | Change |
|------|--------|
| `path/to/file.ts` | Brief description |
```

**If `--draft`**, use shorter format:
```markdown
## Summary

[1-2 sentences]

## TODO

- [ ] [Remaining work items]
```

### 5. Output

Print the generated PR content:

```
## Title

feat: add user avatar upload

## Description

[Full description markdown]
```

**Do not** create the PR automatically. User will copy/paste or pipe to `gh pr create`.

## Examples

### Example 1: Feature Branch
**Branch:** `add-avatar-upload`
**Commits:** 3 commits adding avatar functionality
**Output:**
```
## Title

feat: add user avatar upload with image resizing

## Description

## Summary

Adds avatar upload functionality to user profiles. Images are automatically resized to 200x200px and converted to WebP format for optimal performance.

## Changes

- Add `AvatarUploader` component with drag-and-drop support
- Implement server-side image processing with Sharp
- Add avatar URL field to User model
- Update profile page to display and edit avatar

## Testing

1. Go to Settings > Profile
2. Click avatar placeholder or drag an image
3. Verify image appears resized
4. Refresh page to confirm persistence
```

### Example 2: Bug Fix
**Branch:** `fix-login-timeout`
**Commits:** 1 commit fixing auth issue
**Output:**
```
## Title

fix: resolve session timeout on slow connections

## Description

## Summary

Fixes login failures occurring when authentication requests take longer than 5 seconds. Increases timeout and adds retry logic.

## Changes

- Increase auth request timeout from 5s to 30s
- Add exponential backoff retry (3 attempts)
- Improve error message for timeout failures

## Testing

```bash
npm test -- --grep "auth timeout"
```

Or manually: simulate slow network in DevTools and attempt login.
```

## Quality Checklist

Before outputting:
- [ ] Title follows conventional commit format
- [ ] Title under 72 characters
- [ ] Summary explains the "why"
- [ ] Changes are user/reviewer focused, not implementation details
- [ ] Testing section is actionable
- [ ] Breaking changes called out if present
- [ ] No sensitive information (keys, internal URLs) included
