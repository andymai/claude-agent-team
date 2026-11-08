# House rules for outward-facing writing

Project- or organization-specific rules (a writing policy, a Slack voice, a PR template)
belong in the project's CLAUDE.md or the user's memory. Apply them on top of these rules.

## Always
- The author owns every fact and figure. Every number carries a source and the
  definitional choices behind it (cohort, window, what counts).
- Keep the piece short enough that the author can read all of it and explain it out loud.
- Use plain language that a teammate outside the codebase can follow.
- State each judgment call and its reason. Do not bury it.
- Do not use em dashes or en dashes. Use periods, commas, colons, or parentheses.
- Lead with the result. Cut anything the reader does not need to decide or act.
- State what is true now. Do not narrate "formerly X" chains or "not yet built" negative
  space.

## ASD-STE100
Write the body in ASD-STE100 Simplified Technical English (Issue 9). The venue sets the
tone. These rules set the grammar. They do not apply to titles, headings, quotes, code, or
identifiers.
- Use one word for one meaning, and the same term for the same thing in all of the piece.
  If "make sure" names an action, do not also use "verify", "check", or "confirm" for it.
- Use only simple verb forms: the imperative, the infinitive, and the simple present, past,
  and future. Write "I shipped", not "I have shipped". Write "the job fails", not "the job
  is failing".
- Use the active voice and name the actor: "CI rejected the build", not "the build was
  rejected". Use the passive only when the actor is unknown.
- Write an instruction or an ask in the imperative, with one action in each sentence and
  20 words or fewer.
- Keep a descriptive sentence to 25 words or fewer. Keep a paragraph to one topic and 6
  sentences or fewer.
- Keep noun clusters to 3 words or fewer: "the retry limit for the export queue", not
  "export queue retry limit value".
- Keep the articles, the subjects, and the verbs. A short sentence without them is
  ambiguous.
- Use a vertical list for steps and for 3 or more conditions.
- Start a warning with the command or the condition: "Do not merge before the migration
  runs."

## Checker (`scripts/check.py`)
It fails on em or en dashes outside code and quotes, on a sentence over 25 words, and on a
paragraph over 6 sentences. It warns on the present perfect, on "-ing" verbs, on possible
passives, and on two verbs for what can be one action. Read each warning and fix the real
ones. Some warnings are false matches, such as an adjective ("the port is fixed") or a
noun ("a health check"). It also reports the word count. Everything else is the
sentence-by-sentence fact-check against the sourced fact list.
