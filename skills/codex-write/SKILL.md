---
name: codex-write
description: >
  Write outward-facing prose through the OpenAI Codex CLI instead of directly. Use
  when the deliverable is text another person will read: a design or shaping doc, a
  proposal, a wiki or Notion page, a Slack message, a PR title, body, or reply, a
  review reply, an issue or ticket, an email. You gather the facts and decisions into
  a brief, Codex writes, you fact-check the draft against the brief and run the
  house-rule checker, then show the draft before anything is published. Not for
  code, tests, prompt files, commit messages, or replies to the user in the session.
allowed-tools: [Read, Write, Bash, Grep, Glob]
---

# Codex Write

The point is the model's writing. You own the facts, the decisions, and the fact-check.
Codex owns the sentences, so the brief constrains content, not style, beyond the user's
own rules. Nothing is published until the user has seen the draft and said so.

## Preconditions

- `codex` is on PATH and logged in. Check with `codex login status`. If it is not, stop
  and tell the user; do not write the piece yourself as a fallback unless they say to.
- The user's writing rules are wherever this project keeps them (CLAUDE.md, AGENTS.md,
  memory). Read them before writing the brief; they go into the brief verbatim.

## Steps

### 1. Research

Collect every fact the piece needs, each with a source you observed this session: a
file and line you opened, a query you ran, a URL you fetched, a message you read. Make
the judgment calls yourself and write down the reason for each. Do not proceed until
every fact has a source. Codex gets no credit for anything you did not give it.

### 2. Brief

Fill in `${CLAUDE_PLUGIN_ROOT}/skills/codex-write/reference/brief-template.md`. State
the audience, the purpose, the venue's structure if it has one, the facts with sources,
the decisions with reasons, the user's own writing rules copied verbatim, and a word
target. Do not add style rules of your own. End the brief by asking for the finished
text only, no preamble. Save it to a temp file,
for example `/tmp/codex-write/<slug>.brief.md`.

### 3. Run

```
${CLAUDE_PLUGIN_ROOT}/skills/codex-write/scripts/run.sh BRIEF.md OUT.md --max N
```

`run.sh` calls `codex exec` non-interactively, writes only the final message to
`OUT.md`, then runs `scripts/check.py` on it. The checker fails only on em or en dashes.
It prints the word count and notes when the target is exceeded, without failing. It
never prompts, so no tmux is needed. Add `-C <dir>` after the targets only when Codex
must read project files itself.

If the checker fails, add the rule to the brief and rerun rather than hand-editing.

### 4. Fact-check

Read the draft against the brief one sentence at a time. Any fact, number, name, or
claim that is not in the brief is removed, or verified the same way as in step 1 and
added to the brief. Any fact from the brief that the draft changed is corrected. Quote
the offending sentence when you report a fix.

### 5. Show, then publish

Show the user the draft in a quoted block with the checker's output line. Publish only
when they say so. Publishing means posting, committing, or saving anywhere another
person will read it.

## Self-check before reporting

- Every sentence in the draft traces to a line in the brief.
- `check.py` printed `PASS` on the exact file you are showing.
- The user's own writing rules appear in the brief verbatim, and no style rules of yours do.
- No content in the brief or draft is confidential to a project the venue cannot see.
- You have not published anything yet.
