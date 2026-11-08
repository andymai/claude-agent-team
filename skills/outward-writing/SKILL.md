---
name: outward-writing
description: >
  Write outward-facing prose another person will read: a design or shaping doc, a
  proposal, a wiki page, a Slack message, a PR title, body, or reply, a review reply,
  an issue or ticket, an email. You collect every fact with a source, write the draft
  in ASD-STE100 Simplified Technical English, fact-check it sentence by sentence, and
  run the checker, then show the draft before anything is published. Not for code,
  tests, prompt files, commit messages, or replies to the user in the session.
allowed-tools: [Read, Write, Bash, Grep, Glob]
---

# Outward writing

You own every fact and every sentence. Nothing is published until the user has seen
the draft and said so.

## 1. Facts

List every fact, number, name, and claim the piece needs, each with a source observed
this session: a file and line you opened, a query or command you ran, a URL you
fetched, a message you read. Write down each judgment call with its reason. No source,
no sentence.

## 2. Write

Write the draft yourself from that list. Apply
`${CLAUDE_PLUGIN_ROOT}/skills/outward-writing/reference/house-rules.md` (with its
ASD-STE100 grammar rules), the user's writing rules (CLAUDE.md, memory), and the venue's
structure (the repo's PR template, the doc template). Apply the STE rules as you write.
Do not write a dense draft and simplify it after. For anything posted under the user's
name on GitHub, read two or three of their recent comments first and match that voice.

Stay as precise as the source: a total stays a total, "widened the peer range" does not
become "added support", a value that moved does not "remain". Keep code spans, paths,
and identifiers exactly as written.

Write for the reader as they are. Before the piece relies on a project, tool, or
mechanism the reader has not seen, introduce it, and say what the author did. If the
user needed something explained to them, the reader needs it too.

Write to the reader as someone the user wants to keep working with. When the piece
asks something of them, thank them first, give the reason in terms they would agree
with, make the ask once and plainly, and say what the user will handle. The research
behind a request stays out of the piece: do not cite what you found by looking into
the reader (their fork, profile, other accounts, timestamps), and do not hint at
suspicion you reported to the user. State a rule they must follow as routine ("one
small thing"), not as a warning ("I want to be explicit", "has to be you personally").

Under the user's name, write as the user: "I" for the author, "you" for the reader.
Never name the author in the third person, and never describe the piece itself ("this
deck covers", "I explain").

Write the way a person would say it. Titles and headings are plain sentences, not a
formula: no fixed grammatical template, no per-line word caps (fit space by measuring
the rendered result, then trim), no noun stacks ("Added median wait on the first page"),
no telegraphic fragments ("Pool resets. Memory drops."). The title or first line gets
the most care, because it is read first: it says what changes and what is asked.

## 3. Check

Reread the draft one sentence at a time against the fact list. Remove anything without
a source, and fix anything that changed a fact. Then read it again as the reader: is
everything they do not know introduced, does it sound like the author talking, and do
the titles read naturally in a row without all sharing one shape?

For a change (a PR, a proposal, a ticket), read the first paragraph alone: can the
reader say what happens today, what happens after, and what a user sees differently?
State today's behavior even when the reader wrote the code. If the facts or the design
changed after you drafted, rewrite the lead from the fact list instead of patching the
old sentences: each sentence can stay true while the result it led to moved.

Then read it once more as the reader taking it badly: does any sentence make them
feel watched, suspected, lectured, or talked down to? Rewrite that sentence before
showing the draft.

Then read it for the ASD-STE100 rules. Does one action keep one verb in all of the piece?
Can each passive sentence name its actor? Does any sentence carry two instructions? Then
run:

```
python3 -I "${CLAUDE_PLUGIN_ROOT}/skills/outward-writing/scripts/check.py" DRAFT.md --max N
```

It fails on em or en dashes outside code and quotes, on a sentence over 25 words, and on
a paragraph over 6 sentences. Fix each FAIL. It also warns on the present perfect, "-ing"
verbs, possible passives, and two verbs for one action. Read each warning and fix the
real ones. The first line reports the word count against the target.

## 4. Show, then publish

Show the draft in a quoted block with the checker's output. Publish only when the user
says so. Publishing means posting, committing, or saving anywhere another person will
read it. A project's CLAUDE.md or the user's memory can make an exception, for example
for PR bodies.
