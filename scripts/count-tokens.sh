#!/bin/bash

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <file-path>" >&2
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "ERROR: File not found: $FILE_PATH" >&2
  exit 1
fi

# Reject files larger than 10MB to avoid OOM with jq/API
FILE_SIZE=$(wc -c < "$FILE_PATH")
if [ "$FILE_SIZE" -gt 10485760 ]; then
  echo "ERROR: File too large ($(( FILE_SIZE / 1048576 ))MB > 10MB limit)" >&2
  exit 1
fi

CACHE_FILE="${CLAUDE_PLUGIN_DATA:-$HOME/.cache/claude-agent-team}/token-cache.json"
if command -v md5sum &>/dev/null; then
  FILE_HASH=$(md5sum "$FILE_PATH" | cut -d' ' -f1)
elif command -v md5 &>/dev/null; then
  FILE_HASH=$(md5 -q "$FILE_PATH")
else
  echo "ERROR: No md5 tool found (need md5sum or md5)" >&2
  exit 1
fi

if [ -f "$CACHE_FILE" ] && command -v jq &>/dev/null; then
  CACHED=$(jq -r --arg hash "$FILE_HASH" '.[$hash] // empty' "$CACHE_FILE" 2>/dev/null)
  if [ -n "$CACHED" ]; then
    echo "$CACHED"
    exit 0
  fi
fi

# Callers (context-auditor) depend on always getting a usable count, so this
# exits 0 with an estimate instead of propagating a hard failure.
estimate_tokens() {
  echo "ESTIMATE:$((FILE_SIZE / 3))"
  exit 0
}

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "ERROR: ANTHROPIC_API_KEY environment variable not set" >&2
  estimate_tokens
fi

for tool in jq curl; do
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: $tool is required but not installed" >&2
    estimate_tokens
  fi
done

MODEL="${ANTHROPIC_MODEL:-claude-sonnet-4-5-20250929}"
API_VERSION="${ANTHROPIC_API_VERSION:-2023-06-01}"

CONTENT=$(cat "$FILE_PATH" | jq -Rs .)
RESPONSE=$(curl -s -w "\n%{http_code}" https://api.anthropic.com/v1/messages/count_tokens \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: $API_VERSION" \
  -H "content-type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":$CONTENT}]}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API request failed (HTTP $HTTP_CODE): $(echo "$BODY" | jq -r '.error.message // .error // "Unknown error"')" >&2
  estimate_tokens
fi

TOKENS=$(echo "$BODY" | jq -r '.input_tokens')

mkdir -p "$(dirname "$CACHE_FILE")"
if [ ! -f "$CACHE_FILE" ]; then echo '{}' > "$CACHE_FILE"; fi
# jq cannot write to its own input path: the redirect would truncate the cache
# before jq reads it. The temp name is randomized rather than fixed because the
# cache is shared, so concurrent writers must not collide on it.
TMP_FILE=$(mktemp "${CACHE_FILE}.XXXXXX")
if jq --arg hash "$FILE_HASH" --arg tokens "$TOKENS" \
  '.[$hash] = ($tokens | tonumber)' "$CACHE_FILE" > "$TMP_FILE"; then
  mv "$TMP_FILE" "$CACHE_FILE"
else
  rm -f "$TMP_FILE"
fi

echo "$TOKENS"
