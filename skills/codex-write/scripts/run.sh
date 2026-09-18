#!/usr/bin/env bash
# Run Codex non-interactively on a writing brief, then check the draft.
#
# Usage: run.sh BRIEF.md OUT.md [--max N] [-- extra codex args]
#
# Reads the brief from BRIEF.md, writes only Codex's final message to OUT.md,
# then runs check.py with the same --max. Exit code is the checker's
# (0 pass, 1 fail) or 2 when codex itself failed.
set -euo pipefail

brief="${1:?brief path}"; out="${2:?output path}"; shift 2
check_args=()
codex_args=()
while (($#)); do
  case "$1" in
    --max) check_args+=("$1" "$2"); shift 2 ;;
    --) shift; codex_args=("$@"); break ;;
    *) codex_args+=("$1"); shift ;;
  esac
done

command -v codex >/dev/null || { echo "codex CLI not found on PATH" >&2; exit 2; }

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log="${out%.md}.codex.log"

codex exec --ephemeral --skip-git-repo-check -s read-only \
  -o "$out" "${codex_args[@]}" - < "$brief" > "$log" 2>&1 \
  || { echo "codex exec failed; see $log" >&2; exit 2; }

echo "draft: $out"
python3 "$here/check.py" "$out" "${check_args[@]}"
