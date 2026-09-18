# House rules for outward-facing writing

The skill exists to use the model's writing, so this file is short on style. Project- or
organization-specific rules (a writing policy, a Slack voice, a PR template) belong in
the project's CLAUDE.md or the user's memory; copy them into the brief verbatim.

## Always
- The author owns every fact and figure. Every number carries a source and the
  definitional choices behind it (cohort, window, what counts).
- Decisions stated explicitly with their reasons.
- No em dashes, no en dashes. This is the one rule `scripts/check.py` enforces.
- State what is true now. No "formerly X" chains and no "not yet built" negative space.

## Checker (`scripts/check.py`)
Fails on em or en dashes. Prints the word count and a note when `--max` is exceeded.
