#!/bin/bash
# Token counting script with caching for context-auditor agent
# Uses Anthropic API with fallback to character-based estimation

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <file-path>" >&2
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "ERROR: File not found: $FILE_PATH" >&2
  exit 1
fi

CACHE_FILE=".token-cache.json"
if command -v md5sum &>/dev/null; then
  FILE_HASH=$(md5sum "$FILE_PATH" | cut -d' ' -f1)
elif command -v md5 &>/dev/null; then
  FILE_HASH=$(md5 -q "$FILE_PATH")
else
  echo "ERROR: No md5 tool found (need md5sum or md5)" >&2
  exit 1
fi
FILE_MTIME=$(stat -c %Y "$FILE_PATH" 2>/dev/null || stat -f %m "$FILE_PATH" 2>/dev/null)

# Try to use cache (if file unchanged)
if [ -f "$CACHE_FILE" ]; then
  CACHED=$(jq -r --arg hash "$FILE_HASH" '.[$hash] | select(.mtime == '$FILE_MTIME') | .tokens' "$CACHE_FILE" 2>/dev/null)
  if [ "$CACHED" != "null" ] && [ -n "$CACHED" ]; then
    echo "$CACHED"
    exit 0
  fi
fi

# Count tokens via API with error handling
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "ERROR: ANTHROPIC_API_KEY environment variable not set" >&2
  # Fallback: Character-based estimation (~3.3 chars/token)
  CHARS=$(wc -c < "$FILE_PATH")
  echo $((CHARS / 3))
  exit 0
fi

CONTENT=$(cat "$FILE_PATH" | jq -Rs .)
RESPONSE=$(curl -s -w "\n%{http_code}" https://api.anthropic.com/v1/messages/count_tokens \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{\"model\":\"claude-sonnet-4-5\",\"messages\":[{\"role\":\"user\",\"content\":$CONTENT}]}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: API request failed (HTTP $HTTP_CODE): $(echo $BODY | jq -r '.error.message // .error // "Unknown error"')" >&2
  # Fallback to estimation
  CHARS=$(wc -c < "$FILE_PATH")
  echo $((CHARS / 3))
  exit 0
fi

TOKENS=$(echo "$BODY" | jq -r '.input_tokens')

# Cache the result
mkdir -p "$(dirname "$CACHE_FILE")"
if [ ! -f "$CACHE_FILE" ]; then echo '{}' > "$CACHE_FILE"; fi
jq --arg hash "$FILE_HASH" --arg tokens "$TOKENS" --arg mtime "$FILE_MTIME" \
  '.[$hash] = {tokens: ($tokens | tonumber), mtime: ($mtime | tonumber)}' \
  "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"

echo "$TOKENS"
