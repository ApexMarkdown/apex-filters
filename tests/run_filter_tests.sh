#!/usr/bin/env bash
#
# Run filter tests: clone each filter from apex-filters.json into a temporary
# config directory, then run apex --filter ID with the corresponding fixture.
# Add new filters by adding an entry to apex-filters.json, a fixture under
# tests/fixtures/<id>.md, and optionally a test_<id> assertion below.
#
# Requirements: apex (in PATH), git, jq (for parsing apex-filters.json).
# Lua filters (unwrap, uppercase) require: lua, luarocks, and luarocks install dkjson.
#

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/tests/fixtures"
JSON_FILE="$REPO_ROOT/apex-filters.json"
FAILED=0

if ! command -v apex &>/dev/null; then
  echo "Error: apex not found in PATH. Install Apex to run filter tests." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq not found. Install jq to parse apex-filters.json." >&2
  exit 1
fi

# Create temporary config and filters directory so we don't touch the user's config
TMP_CONFIG="$(mktemp -d)"
trap 'rm -rf "$TMP_CONFIG"' EXIT
FILTERS_ROOT="$TMP_CONFIG/apex/filters"
mkdir -p "$FILTERS_ROOT"
export XDG_CONFIG_HOME="$TMP_CONFIG"

echo "Using temporary config: $TMP_CONFIG"
echo ""

# Clone a filter repo into filters/<id> (or, if path is set, copy that single file to filters/<id>)
# Usage: clone_filter ID REPO [PATH]
# If PATH is set (e.g. "src/code-includes.lua"), clone to temp, copy PATH to filters/<id>, remove temp.
clone_filter() {
  local id="$1"
  local repo="$2"
  local path="$3"
  local dest="$FILTERS_ROOT/$id"

  if [[ -n "$path" ]]; then
    # Single-file install: clone to temp, copy path to filters/<id>, rm temp
    local temp="$FILTERS_ROOT/.apex_test_$id"
    if [[ -f "$dest" ]]; then
      echo "  (already installed)"
    else
      git clone --depth 1 --quiet "$repo" "$temp"
      cp "$temp/$path" "$dest"
      chmod +x "$dest"
      rm -rf "$temp"
    fi
    return 0
  fi

  if [[ -d "$dest" ]]; then
    echo "  (already cloned)"
  else
    git clone --depth 1 --quiet "$repo" "$dest"
  fi
  # Apex runs the filter script directly; ensure it is executable
  for script in "$dest/$id" "$dest/$id.lua" "$dest/$id.py" "$dest/$id.rb"; do
    if [[ -f "$script" ]]; then
      chmod +x "$script"
      return 0
    fi
  done
  return 1
}

# Run apex --filter <id> on the fixture and return exit code; output is in stdout
run_filter() {
  local id="$1"
  local fixture="$2"
  apex --filter "$id" "$fixture" 2>/dev/null
}

# Test one filter: clone, run, optional content check
# Usage: test_filter ID REPO [PATH]
test_filter() {
  local id="$1"
  local repo="$2"
  local path="${3:-}"
  local fixture="$FIXTURES_DIR/$id.md"

  echo -n "Testing filter: $id ... "

  if [[ ! -f "$fixture" ]]; then
    echo "SKIP (no fixture $id.md)"
    return 0
  fi

  clone_filter "$id" "$repo" "$path" || { echo "FAIL (clone)"; FAILED=$((FAILED + 1)); return 1; }

  local out
  out="$(run_filter "$id" "$fixture")" || { echo "FAIL (apex exit)"; FAILED=$((FAILED + 1)); return 1; }

  # Optional: run filter-specific assertion if function exists
  if declare -f "test_$id" &>/dev/null; then
    if ! "test_$id" "$out"; then
      echo "FAIL (assertion)"; FAILED=$((FAILED + 1)); return 1
    fi
  fi

  echo "OK"
  return 0
}

# --- Filter-specific assertions (add one per new filter as needed) ---

test_title() {
  local out="$1"
  # When apex passes meta.title to the AST, filter adds an H1
  if echo "$out" | grep -q '<h1[^>]*>Document Title From Meta</h1>'; then
    return 0
  fi
  # Otherwise just ensure filter ran and body is present
  echo "$out" | grep -q 'This document has no level-1 heading' || return 1
}

test_delink() {
  local out="$1"
  # Filter removes link targets; output must not contain the raw link
  echo "$out" | grep -q 'Links should become plain text' || return 1
  ! echo "$out" | grep -q '<a href="https://example.com"' || return 1
}

test_uppercase() {
  local out="$1"
  echo "$out" | grep -q 'THIS SENTENCE SHOULD APPEAR IN ALL UPPERCASE' || return 1
}

test_unwrap() {
  local out="$1"
  # Unwrap turns angle-prefixed paragraph into raw HTML
  echo "$out" | grep -q 'unwrap-me' || return 1
  echo "$out" | grep -q 'This block should be unwrapped to raw HTML' || return 1
}

# --- Main: read filters from JSON and test each ---

if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: $JSON_FILE not found." >&2
  exit 1
fi

  count=0
while read -r line; do
  id="$(echo "$line" | jq -r '.id')"
  repo="$(echo "$line" | jq -r '.repo')"
  path="$(echo "$line" | jq -r '.path // empty')"
  [[ "$id" == "null" || "$repo" == "null" ]] && continue
  test_filter "$id" "$repo" "$path" || true
  ((count++)) || true
done < <(jq -c '.filters[]?' "$JSON_FILE")

echo ""
if [[ $FAILED -gt 0 ]]; then
  echo "Result: $FAILED test(s) failed."
  exit 1
fi
echo "Result: all $count filter test(s) passed."
exit 0
