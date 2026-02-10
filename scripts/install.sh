#!/usr/bin/env bash
set -euo pipefail

# Install claude-agent-team agents and commands into ~/.claude/
# Tracks checksums to detect local modifications and avoid clobbering.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_DIR="$HOME/.claude"
CHECKSUM_FILE="$DEST_DIR/.checksums"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- State ---
DRY_RUN=false
VERBOSE=false
ACTION=""
INSTALLED=0
SKIPPED=0
UPDATED=0
REMOVED=0

usage() {
  cat <<'EOF'
Usage: install.sh [OPTIONS]

Options:
  --uninstall   Remove all installed files and checksums
  --status      Show install status of all files
  --dry-run     Preview changes without modifying anything
  --verbose     Detailed logging of each operation
  --help        Show this help message

Without flags, installs agents/, commands/, and scripts/ into ~/.claude/.
EOF
  exit 0
}

# --- Helpers ---

log()     { echo -e "${GREEN}[+]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[x]${RESET} $*"; }
info()    { echo -e "${CYAN}[i]${RESET} $*"; }
verbose() { $VERBOSE && echo -e "    $*" || true; }

sha256() {
  if command -v sha256sum &>/dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    error "No sha256 tool found (need sha256sum or shasum)"
    exit 1
  fi
}

# Load checksum DB into associative array
declare -A CHECKSUMS
load_checksums() {
  CHECKSUMS=()
  if [[ -f "$CHECKSUM_FILE" ]]; then
    while IFS='=' read -r key value; do
      [[ -n "$key" && -n "$value" ]] && CHECKSUMS["$key"]="$value"
    done < "$CHECKSUM_FILE"
  fi
}

save_checksums() {
  if $DRY_RUN; then return; fi
  mkdir -p "$(dirname "$CHECKSUM_FILE")"
  : > "$CHECKSUM_FILE"
  for key in "${!CHECKSUMS[@]}"; do
    echo "${key}=${CHECKSUMS[$key]}" >> "$CHECKSUM_FILE"
  done
}

record_checksum() {
  local dest="$1"
  CHECKSUMS["$dest"]="$(sha256 "$dest")"
}

# Collect all source files (relative paths like agents/foo.md, commands/bar.md, scripts/foo.sh)
collect_files() {
  local files=()
  for dir in agents commands scripts; do
    local src_dir="$REPO_DIR/$dir"
    [[ -d "$src_dir" ]] || continue
    local pattern='*.md'
    [[ "$dir" == "scripts" ]] && pattern='*.sh'
    while IFS= read -r -d '' f; do
      files+=("${f#"$REPO_DIR/"}")
    done < <(find "$src_dir" -type f -name "$pattern" -print0)
  done
  echo "${files[@]}"
}

# --- Core Operations ---

install_file() {
  local rel="$1"
  local src="$REPO_DIR/$rel"
  local dest="$DEST_DIR/$rel"
  local src_hash dest_hash recorded_hash

  src_hash="$(sha256 "$src")"

  if [[ -f "$dest" ]]; then
    dest_hash="$(sha256 "$dest")"

    # Already identical
    if [[ "$src_hash" == "$dest_hash" ]]; then
      # Seed checksum if not yet tracked
      if [[ -z "${CHECKSUMS[$dest]:-}" ]]; then
        record_checksum "$dest"
        verbose "tracked: $rel"
      else
        verbose "unchanged: $rel"
      fi
      SKIPPED=$((SKIPPED + 1))
      return
    fi

    # Check if user modified the installed file
    recorded_hash="${CHECKSUMS[$dest]:-}"

    if [[ -n "$recorded_hash" && "$recorded_hash" != "$dest_hash" ]]; then
      # Destination was modified since we last installed it
      warn "Local modifications detected: ${BOLD}$rel${RESET}"
      echo ""
      if command -v diff &>/dev/null; then
        diff --color=auto -u "$dest" "$src" | head -30 || true
        local total_lines
        total_lines=$( (diff -u "$dest" "$src" || true) | wc -l)
        if [[ "$total_lines" -gt 30 ]]; then
          echo "    ... ($((total_lines - 30)) more lines)"
        fi
      fi
      echo ""

      while true; do
        echo -en "  ${CYAN}(o)verwrite  (s)kip  (d)iff${RESET} > "
        read -r choice
        case "$choice" in
          o|O|overwrite)
            if $DRY_RUN; then
              info "would overwrite: $rel"
            else
              mkdir -p "$(dirname "$dest")"
              cp "$src" "$dest"
              record_checksum "$dest"
              log "overwritten: $rel"
            fi
            UPDATED=$((UPDATED + 1))
            return
            ;;
          s|S|skip)
            warn "skipped: $rel"
            SKIPPED=$((SKIPPED + 1))
            return
            ;;
          d|D|diff)
            diff --color=auto -u "$dest" "$src" || true
            ;;
          *) echo "  Enter o, s, or d" ;;
        esac
      done
    else
      # Destination exists but wasn't locally modified — safe to update
      if $DRY_RUN; then
        info "would update: $rel"
      else
        cp "$src" "$dest"
        record_checksum "$dest"
        log "updated: $rel"
      fi
      UPDATED=$((UPDATED + 1))
    fi
  else
    # New file
    if $DRY_RUN; then
      info "would install: $rel"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      record_checksum "$dest"
      log "installed: $rel"
    fi
    INSTALLED=$((INSTALLED + 1))
  fi
}

do_install() {
  info "Installing from ${BOLD}$REPO_DIR${RESET} → ${BOLD}$DEST_DIR${RESET}"
  $DRY_RUN && warn "Dry run — no files will be modified"
  echo ""

  load_checksums

  local files
  read -ra files <<< "$(collect_files)"

  if [[ ${#files[@]} -eq 0 ]]; then
    error "No files found in agents/, commands/, or scripts/"
    exit 1
  fi

  for rel in "${files[@]}"; do
    install_file "$rel"
  done

  save_checksums

  echo ""
  echo -e "${BOLD}Summary:${RESET} ${GREEN}$INSTALLED installed${RESET}, ${CYAN}$UPDATED updated${RESET}, ${YELLOW}$SKIPPED unchanged${RESET}"
}

do_uninstall() {
  info "Uninstalling claude-agent-team files from ${BOLD}$DEST_DIR${RESET}"
  $DRY_RUN && warn "Dry run — no files will be modified"
  echo ""

  load_checksums

  local files
  read -ra files <<< "$(collect_files)"

  for rel in "${files[@]}"; do
    local dest="$DEST_DIR/$rel"
    if [[ -f "$dest" ]]; then
      if $DRY_RUN; then
        info "would remove: $rel"
      else
        rm "$dest"
        unset "CHECKSUMS[$dest]"
        log "removed: $rel"
      fi
      REMOVED=$((REMOVED + 1))
    else
      verbose "not installed: $rel"
    fi
  done

  if ! $DRY_RUN && [[ -f "$CHECKSUM_FILE" ]]; then
    # Clean up checksums for removed files; keep others
    save_checksums
    # If no checksums remain, remove the file
    if [[ ! -s "$CHECKSUM_FILE" ]]; then
      rm -f "$CHECKSUM_FILE"
    fi
  fi

  echo ""
  echo -e "${BOLD}Summary:${RESET} ${RED}$REMOVED removed${RESET}"
}

do_status() {
  info "Status of claude-agent-team files in ${BOLD}$DEST_DIR${RESET}"
  echo ""

  load_checksums

  local files
  read -ra files <<< "$(collect_files)"

  printf "  ${BOLD}%-40s %s${RESET}\n" "FILE" "STATUS"
  printf "  %-40s %s\n" "────────────────────────────────────────" "──────────────"

  for rel in "${files[@]}"; do
    local src="$REPO_DIR/$rel"
    local dest="$DEST_DIR/$rel"
    local status

    if [[ ! -f "$dest" ]]; then
      status="${RED}not installed${RESET}"
    else
      local src_hash dest_hash recorded_hash
      src_hash="$(sha256 "$src")"
      dest_hash="$(sha256 "$dest")"
      recorded_hash="${CHECKSUMS[$dest]:-}"

      if [[ "$src_hash" == "$dest_hash" ]]; then
        status="${GREEN}up to date${RESET}"
      elif [[ -n "$recorded_hash" && "$recorded_hash" != "$dest_hash" ]]; then
        status="${YELLOW}locally modified${RESET}"
      else
        status="${CYAN}update available${RESET}"
      fi
    fi

    printf "  %-40s %b\n" "$rel" "$status"
  done
  echo ""
}

# --- Parse Args ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall)  ACTION="uninstall"; shift ;;
    --status)     ACTION="status"; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --verbose)    VERBOSE=true; shift ;;
    --help|-h)    usage ;;
    *)            error "Unknown option: $1"; usage ;;
  esac
done

# --- Run ---

case "${ACTION:-install}" in
  install)   do_install ;;
  uninstall) do_uninstall ;;
  status)    do_status ;;
esac
