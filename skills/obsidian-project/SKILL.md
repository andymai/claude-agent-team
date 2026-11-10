---
name: obsidian-project
description: >
  Start a new project in an Obsidian vault. It writes one folder of prefix-named notes
  (overview, PRD, architecture, research, tasks), links them, and adds the project to
  the vault's index. Use when the user asks to start, set up, or scaffold a project,
  a project folder, or project docs in Obsidian or in their vault. Also holds the
  conventions for links, tags, and tasks when you update those notes later.
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# Obsidian project

Create one folder of linked notes for a new project in an Obsidian vault, then add the
project to the vault's index. Each note starts from a template in
`${CLAUDE_PLUGIN_ROOT}/skills/obsidian-project/templates/`.

## 1. Find the vault

Use the first rule that gives you one folder:

1. The user names the vault folder.
2. The user's CLAUDE.md or memory gives the vault path.
3. A search of the home folder finds exactly one vault. Each match's parent folder is
   a vault:

   ```bash
   find ~ -maxdepth 4 -type d -name .obsidian -not -path '*/.Trash/*' 2>/dev/null
   ```

If the search finds no vault or more than one, ask the user which folder to use. Do not
guess.

Gate: do not continue until you have one vault folder and it exists.

## 2. Read the vault's own rules

Read `CLAUDE.md`, `AGENTS.md`, and `README.md` at the vault root if they exist. If one
of them describes a project layout, follow that layout instead of these templates, and
say so in the report. The vault's rules win over this skill.

## 3. Name the project

- `{title}`: the project name as the user writes it.
- `{name}`: the file prefix. If the project has a repo, use the repo name in lowercase.
  Otherwise, write `{title}` in lowercase. Change each space, and each character that
  is not a letter, a digit, `-`, or `_`, to one hyphen. Example:
  "CI/CD Dashboard" gives `ci-cd-dashboard`.
- `{date}`: today, as `YYYY-MM-DD`.

Gate: `{name}` becomes a folder name and part of each file name, so it must pass this
check. Put the name in place of `<name>`:

```bash
printf '%s' '<name>' | grep -Eq '^[a-z0-9][a-z0-9_-]*$' && echo ok
```

If the check does not print `ok`, ask the user for a different name.

Obsidian finds a wikilink's note by file name anywhere in the vault, so each file name
must be unique. Check the five names before you write anything:

```bash
find "<vault>" -type f \( -name "{name}.md" -o -name "{name}-prd.md" \
  -o -name "{name}-architecture.md" -o -name "{name}-research.md" \
  -o -name "{name}-tasks.md" \) -not -path '*/.trash/*'
ls -d "<vault>/Projects/{name}" 2>/dev/null
```

Gate: if either command prints a path, stop and ask the user for a different name. Do
not overwrite or merge notes.

If `<vault>/Projects/` does not exist, ask the user where projects go, or if you can
create `Projects/`.

## 4. Write the notes

Create `<vault>/Projects/{name}/`. For each template, read it, replace every `{name}`,
`{title}`, and `{date}`, and write the note:

| Template | Note |
|---|---|
| `overview.md` | `{name}.md` |
| `prd.md` | `{name}-prd.md` |
| `architecture.md` | `{name}-architecture.md` |
| `research.md` | `{name}-research.md` |
| `tasks.md` | `{name}-tasks.md` |

Fill a section only from what the user told you or what you read in this session. Good
sources are the repo, a linked doc, and earlier notes in the vault. Where you have nothing, keep the
template's `%% ... %%` prompt. Obsidian hides these comments in reading view. Never
invent goals, requirements, metrics, or stack choices to fill a section.

Example. The user says "a CLI that renames photos by EXIF date, in Rust".

- Good: the Stack table gets `| CLI | Rust | The user's choice |`. The Problem section
  keeps its prompt.
- Bad: a Problem paragraph about "photographers who lose hours to sorting files". Nobody
  said that.

Before you write research, search the vault for earlier notes on the same topic. Look
in `Knowledge/` first if it exists. Link those notes from the research note, and do not
repeat their content.

## 5. Add the project to the index

Look for an index note with a list of projects. This note is a map of content, often
`index.md` or `Home.md`. If you find one, add one line for the new project, such as
`- [[{name}]]: <one sentence about the project>`. Match the format of the lines next to
it. If the vault has no such list, skip this step and say so in the report. Do not
create an index.

## 6. Check, then report

Run each check, and fix any failure before you report:

- [ ] `ls "<vault>/Projects/{name}"` shows the five notes.
- [ ] No note still has a placeholder. In this command, replace only the folder path,
  and keep the three search terms with their braces:
  `grep -rnF -e '{name}' -e '{title}' -e '{date}' "<vault>/Projects/<project folder>"`.
  It must print nothing.
- [ ] Each `[[...]]` link in the overview names a note that exists.
- [ ] Each note starts with frontmatter that has a `tags:` array.

Report these items:

- The folder path and the five notes.
- What you filled, and where each fact came from.
- The sections that still have only a prompt.
- The index line, or why you skipped it.

## Conventions for project notes

These rules apply when you write the notes and when you update them later.

- **Links**: use wikilinks with the project prefix, such as `[[{name}-prd]]`. The prefix
  keeps file names unique, so a link never opens another project's note.
- **Tags**: use frontmatter arrays only, such as `tags: [prd, draft]`.
  - Status: `active`, `draft`, `blocked`, `archived`.
  - Type: `project`, `prd`, `architecture`, `research`, `task`, `knowledge`.
  - Domain, if it helps: `web`, `cli`, `infra`, `api`, `mobile`, `data`.
- **Tasks**: use plain `- [ ]` and `- [x]` lines. Do not add emoji dates or priorities.
- **Settled rules**: when work settles a rule, write it into the architecture note where
  it applies, and state what is true now. Do not keep a separate decision log, because
  old entries fill the context with history.
- **More notes**: when a topic outgrows its section, give it its own note with the same
  prefix, such as `{name}-roadmap.md`. Link the new note from the overview's Quick Links.
- **Status changes**: when the project becomes active, blocked, or archived, change the
  status tag in each note and update the project's line in the index.
