#!/usr/bin/env python3
"""Mechanical check on a Codex-written draft.

Fails only on em or en dashes. Reports the word count, and warns (exit 0) when a
--max target is exceeded, so the model's own judgment on length is not overridden.

Usage: check.py DRAFT.md [--max N]
"""

import argparse
import re
import sys

DASHES = {"—": "em dash", "–": "en dash"}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("draft")
    ap.add_argument("--max", type=int, default=0)
    args = ap.parse_args()

    text = open(args.draft, encoding="utf-8").read()
    words = len(re.findall(r"\S+", re.sub(r"```.*?```", "", text, flags=re.S)))
    print(f"words: {words}")
    if args.max and words > args.max:
        print(f"note: over the {args.max}-word target")

    failures = [f"{text.count(ch)} {name}(s)" for ch, name in DASHES.items() if ch in text]
    if failures:
        print("FAIL: " + ", ".join(failures))
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
