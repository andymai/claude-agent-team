#!/usr/bin/env python3
import argparse
import re
import sys

DASHES = {"—": "em dash", "–": "en dash"}
MAX_SENTENCE_WORDS = 25
MAX_PARAGRAPH_SENTENCES = 6

FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
SETEXT_UNDERLINE = re.compile(r"^\s*(=+|-{2,})\s*$")
SKIP_LINE = re.compile(r"^\s*(#{1,6}\s|\||>|(-{3,}|\*{3,}|_{3,})\s*$|<[^>]+>\s*$)")
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?")
ABBREVIATION = re.compile(r"\b(e\.g|i\.e|vs|etc|cf|approx|incl|a\.m|p\.m)\.", re.I)
SENTENCE_BREAK = re.compile(r"(?<=[.!?])[\"')\]”’]*\s+")
HTML_COMMENT = re.compile(r"<!--.*?-->", re.S)
QUOTE_LINE = re.compile(r"^\s*>")
INLINE_CODE = re.compile(r"(`+).+?\1")
QUOTED = re.compile(r'"[^"\n]*"|“[^”\n]*”')
URL = re.compile(r"https?://\S*[^\s.,;:!?)\]'\"”’]")
WORD = re.compile(r"[A-Za-z0-9]")

IRREGULAR = (
    "been|done|gone|made|seen|written|taken|given|run|built|shown|known|found|got|"
    "gotten|begun|broken|chosen|driven|fallen|forgotten|grown|hidden|left|lost|kept|"
    "held|sent|set|put|read|said|told|thought|brought|bought|caught|taught|felt|meant|"
    "met|paid|sold|spent|stood|understood|won|thrown|split|shut|hit|cut|let"
)
APOSTROPHE = "['’]"
PRESENT_PERFECT = re.compile(
    rf"(?:\b(?:has|have|had|hasn't|haven't|hadn't)|{APOSTROPHE}ve)\s+(?:not\s+)?(?:\w+ly\s+)?"
    rf"(?:\w+ed|{IRREGULAR})\b",
    re.I,
)
BE = (
    rf"(?:\b(?:am|is|are|was|were|be|been|being|isn't|aren't|wasn't|weren't)"
    rf"|\b(?:it|that|what|who|where|there|here|he|she|this){APOSTROPHE}s|{APOSTROPHE}(?:re|m))"
)
PROGRESSIVE = re.compile(rf"{BE}\s+(?:not\s+)?(?:\w+ly\s+)?(\w+ing)\b", re.I)
PASSIVE = re.compile(rf"{BE}\s+(?:not\s+)?(?:\w+ly\s+)?(?:\w+ed|{IRREGULAR})\b", re.I)
NOT_A_VERB = {
    "nothing", "something", "anything", "everything", "thing", "things", "string",
    "strings", "during", "bring", "spring", "morning", "evening", "ceiling", "king", "ring",
}

ONE_ACTION_VERBS = [
    {
        "make sure": r"\b(?:make|makes|made|making)\s+sure\b",
        "check": r"\bcheck(?:s|ed|ing)?\b",
        "verify": r"\bverif(?:y|ies|ied|ying)\b",
        "confirm": r"\bconfirm(?:s|ed|ing)?\b",
        "ensure": r"\bensur(?:e|es|ed|ing)\b",
        "validate": r"\bvalidat(?:e|es|ed|ing)\b",
    },
    {
        "fix": r"\bfix(?:es|ed|ing)?\b",
        "resolve": r"\bresolv(?:e|es|ed|ing)\b",
        "address": r"\baddress(?:es|ed|ing)?\b",
    },
    {
        "start": r"\bstart(?:s|ed|ing)?\b",
        "begin": r"\bbegin(?:s|ning)?\b|\bbeg[au]n\b",
        "launch": r"\blaunch(?:es|ed|ing)?\b",
        "kick off": r"\bkick(?:s|ed|ing)?\s+off\b",
    },
    {
        "use": r"\bus(?:e|es|ed|ing)\b",
        "utilize": r"\butiliz(?:e|es|ed|ing)\b",
        "leverage": r"\bleverag(?:e|es|ed|ing)\b",
    },
]


def strip_comments(text):
    return HTML_COMMENT.sub(lambda m: "\n" * m.group(0).count("\n"), text)


def fence_step(line, open_fence):
    match = FENCE.match(line)
    if not match:
        return open_fence, False
    marker = match.group(1)
    if open_fence is None:
        return marker, True
    rest = line.strip()[len(marker):].strip()
    if marker[0] == open_fence[0] and len(marker) >= len(open_fence) and not rest:
        return None, True
    return open_fence, False


def quote_token(match):
    inner = match.group(0)[1:-1].rstrip()
    return "QUOTE." if inner.endswith((".", "!", "?")) else "QUOTE"


def dash_findings(text):
    found, open_fence = [], None
    for number, line in enumerate(strip_comments(text).splitlines(), start=1):
        open_fence, is_delimiter = fence_step(line, open_fence)
        if is_delimiter or open_fence or QUOTE_LINE.match(line):
            continue
        line = QUOTED.sub("", INLINE_CODE.sub("", line))
        for ch, name in DASHES.items():
            if ch in line:
                found.append((number, "FAIL", f"{line.count(ch)} {name}(s)"))
    return found


def prose_blocks(text):
    blocks, block, open_fence = [], [], None
    in_list_item = [False]

    def flush():
        if block:
            blocks.append(list(block))
        block.clear()
        in_list_item[0] = False

    for number, raw in enumerate(strip_comments(text).splitlines(), start=1):
        open_fence, is_delimiter = fence_step(raw, open_fence)
        if is_delimiter or open_fence:
            flush()
            continue
        if SETEXT_UNDERLINE.match(raw) and block and (not in_list_item[0] or raw[:1].isspace()):
            block.pop()
            flush()
            continue
        if not raw.strip() or SKIP_LINE.match(raw):
            flush()
            continue
        if LIST_ITEM.match(raw):
            flush()
            in_list_item[0] = True
        line = LIST_ITEM.sub("", raw, count=1)
        line = INLINE_CODE.sub("CODE", line)
        line = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", line)
        line = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", line)
        line = URL.sub("URL", line)
        line = QUOTED.sub(quote_token, line)
        line = ABBREVIATION.sub(lambda m: m.group(1).replace(".", ""), line)
        block.append((number, line.strip()))
    flush()
    return blocks


def sentences(block):
    joined, starts = "", []
    for number, line in block:
        if joined:
            joined += " "
        starts.append((len(joined), number))
        joined += line
    found, position = [], 0
    for match in list(SENTENCE_BREAK.finditer(joined)) + [None]:
        end = match.start() if match else len(joined)
        piece = joined[position:end].strip()
        if WORD.search(piece):
            number = [n for offset, n in starts if offset <= position][-1]
            found.append((number, piece))
        if match:
            position = match.end()
    return found


def word_count(sentence):
    return sum(1 for token in sentence.split() if WORD.search(token))


def preview(sentence, width=60):
    return sentence if len(sentence) <= width else sentence[: width - 3] + "..."


def main():
    parser = argparse.ArgumentParser(
        description="Check an outward-facing draft for dashes and ASD-STE100 limits."
    )
    parser.add_argument("draft")
    parser.add_argument("--max", type=int, default=0, help="word-count target")
    args = parser.parse_args()

    with open(args.draft, encoding="utf-8") as handle:
        text = handle.read()
    words = len(re.findall(r"\S+", re.sub(r"```.*?```", "", text, flags=re.S)))
    print(f"words: {words}")
    if args.max and words > args.max:
        print(f"note: over the {args.max}-word target")

    findings = []
    blocks = prose_blocks(text)
    for block in blocks:
        found = sentences(block)
        if len(found) > MAX_PARAGRAPH_SENTENCES:
            findings.append((found[0][0], "FAIL", f"paragraph has {len(found)} sentences (max {MAX_PARAGRAPH_SENTENCES})"))
        for number, sentence in found:
            count = word_count(sentence)
            if count > MAX_SENTENCE_WORDS:
                findings.append((number, "FAIL", f'sentence has {count} words (max {MAX_SENTENCE_WORDS}): "{preview(sentence)}"'))
            for match in PRESENT_PERFECT.finditer(sentence):
                findings.append((number, "warn", f'present perfect "{match.group(0)}": use the simple past'))
            for match in PROGRESSIVE.finditer(sentence):
                if match.group(1).lower() not in NOT_A_VERB:
                    findings.append((number, "warn", f'"-ing" verb "{match.group(0)}": use the simple present or past'))
            for match in PASSIVE.finditer(sentence):
                findings.append((number, "warn", f'possible passive "{match.group(0)}": name the actor'))

    prose = [(number, line) for block in blocks for number, line in block]
    for group in ONE_ACTION_VERBS:
        first_seen = {}
        for name, pattern in group.items():
            for number, line in prose:
                if re.search(pattern, line, re.I):
                    first_seen[name] = number
                    break
        if len(first_seen) > 1:
            used = ", ".join(f"{name} (line {number})" for name, number in sorted(first_seen.items(), key=lambda item: item[1]))
            findings.append((min(first_seen.values()), "warn", f"one action, more than one verb? {used}: keep one if they mean the same"))

    findings.extend(dash_findings(text))
    for number, level, message in sorted(findings, key=lambda item: (item[0], item[1] != "FAIL")):
        print(f"{level} line {number}: {message}")

    failed = any(level == "FAIL" for _, level, _ in findings)
    print("FAIL" if failed else "PASS")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
