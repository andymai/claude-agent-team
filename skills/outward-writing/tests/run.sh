#!/usr/bin/env bash
# A pass-* draft must exit 0 and a fail-* draft must exit 1. A line
# `<!-- expect: X -->` requires X in the output; `<!-- reject: X -->` forbids it.
set -u
dir="$(cd "$(dirname "$0")" && pwd)"
check="$dir/../scripts/check.py"
mismatches=""
count=0
for draft in "$dir"/*.md; do
    [ -f "$draft" ] || continue
    count=$((count + 1))
    name="${draft##*/}"
    out="$(python3 -I "$check" "$draft" 2>&1)"
    rc=$?
    case "$name" in
        pass-*) [ "$rc" -eq 0 ] || mismatches="$mismatches $name:exit=$rc" ;;
        fail-*) [ "$rc" -eq 1 ] || mismatches="$mismatches $name:exit=$rc" ;;
        *) mismatches="$mismatches $name:no-pass-or-fail-prefix" ;;
    esac
    while IFS= read -r want; do
        case "$out" in *"$want"*) ;; *) mismatches="$mismatches $name:missing[$want]" ;; esac
    done < <(sed -n 's/^<!-- expect: \(.*\) -->$/\1/p' "$draft")
    while IFS= read -r unwanted; do
        case "$out" in *"$unwanted"*) mismatches="$mismatches $name:has[$unwanted]" ;; esac
    done < <(sed -n 's/^<!-- reject: \(.*\) -->$/\1/p' "$draft")
done
if [ "$count" -eq 0 ]; then
    echo "FAIL: no test drafts in $dir"
    exit 1
fi
if [ -n "$mismatches" ]; then
    echo "FAIL:$mismatches"
    exit 1
fi
echo "PASS: $count drafts"
