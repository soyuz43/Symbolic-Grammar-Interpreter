#!/bin/bash

# validate_doc_crosslinks.sh — Verifies structural integrity of documentation links
# Scans docs/*.md for markdown links and validates internal, relative, and header targets
# Usage: ./scripts/falsification/validate_doc_crosslinks.sh

set -o errexit
set -o nounset
set -o pipefail

DOC_ROOT="philosophy/docs"
TMP_LINKS="$(mktemp)"
TMP_HEADERS="$(mktemp)"
FAILURES=0

trap 'rm -f "$TMP_LINKS" "$TMP_HEADERS"' EXIT

extract_links() {
  local file="$1"
  grep -oE '\[.*?\]\(([^)]+)\)' "$file" | sed -E 's/.*\(([^)]+)\)/\1/' | while read -r link; do
    printf "%s|%s\n" "$file" "$link"
  done
}

extract_headers() {
  local file="$1"
  grep -E '^#{1,6} ' "$file" | sed -E 's/^#+[[:space:]]*//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9\-]//g'
}

validate_link() {
  local source="$1"
  local link="$2"

  if [[ "$link" =~ ^https?:// ]]; then
    return 0  # Skip external links
  fi

  local doc_dir; doc_dir=$(dirname "$source")
  local target_path target_anchor

  if [[ "$link" == *"#"* ]]; then
    target_path="${link%%#*}"
    target_anchor="${link##*#}"
  else
    target_path="$link"
    target_anchor=""
  fi

  local full_target="$doc_dir/$target_path"
  full_target=$(realpath --no-symlinks "$full_target" 2>/dev/null || true)

  if [[ ! -f "$full_target" ]]; then
    printf "❌ %s → Broken file path: %s\n" "$source" "$link"
    ((FAILURES++))
    return
  fi

  if [[ -n "$target_anchor" ]]; then
    extract_headers "$full_target" > "$TMP_HEADERS"
    if ! grep -Fxq "$target_anchor" "$TMP_HEADERS"; then
      printf "❌ %s → Invalid header anchor in %s: #%s\n" "$source" "$target_path" "$target_anchor"
      ((FAILURES++))
    fi
  fi
}

main() {
  find "$DOC_ROOT" -type f -name "*.md" | while read -r file; do
    extract_links "$file" >> "$TMP_LINKS"
  done

  cut -d'|' -f2 "$TMP_LINKS" | sort | uniq > /dev/null  # Just trigger parsing

  while IFS='|' read -r source link; do
    validate_link "$source" "$link"
  done < "$TMP_LINKS"

  if ((FAILURES > 0)); then
    printf "\n❌ %d link validation errors found.\n" "$FAILURES"
    exit 1
  else
    printf "✅ All documentation links are valid.\n"
  fi
}

main
