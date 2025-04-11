#!/bin/bash
# validate_license_block.sh — Validates LICENSE.md against critical license clauses and canonical structure

set -euo pipefail

CANONICAL="philosophy/docs/license_baseline.md"
CURRENT="LICENSE.md"

if [[ ! -f "$CURRENT" ]]; then
  echo "❌ Error: $CURRENT not found."
  exit 1
fi

if [[ ! -f "$CANONICAL" ]]; then
  echo "❌ Error: Canonical baseline file '$CANONICAL' not found. Cannot validate license structure."
  exit 1
fi

echo "🔍 Validating required license phrases in $CURRENT..."
REQUIRED_PHRASES=("CC-BY-NC-SA 4.0" "AGPLv3")
for phrase in "${REQUIRED_PHRASES[@]}"; do
  if ! grep -qF "$phrase" "$CURRENT"; then
    echo "❌ Error: Required phrase '$phrase' not found in $CURRENT."
    exit 1
  else
    echo "✅ Found required phrase: '$phrase'"
  fi
done

echo "🔍 Performing basic markdown integrity check..."
open_brackets=$(grep -o "\[" "$CURRENT" | wc -l)
close_brackets=$(grep -o "\]" "$CURRENT" | wc -l)
open_parens=$(grep -o "(" "$CURRENT" | wc -l)
close_parens=$(grep -o ")" "$CURRENT" | wc -l)

if [ "$open_brackets" -ne "$close_brackets" ]; then
  echo "❌ Markdown error: Mismatched square brackets."
  exit 1
fi

if [ "$open_parens" -ne "$close_parens" ]; then
  echo "❌ Markdown error: Mismatched parentheses."
  exit 1
fi
echo "✅ Markdown structure validated."

echo "🔍 Comparing LICENSE.md to canonical version..."
DIFF_OUTPUT=$(diff --unchanged-line-format= --old-line-format='❌ Removed: %L' --new-line-format='➕ Added: %L' "$CANONICAL" "$CURRENT")
if [[ -n "$DIFF_OUTPUT" ]]; then
  echo "❌ LICENSE.md diverges from the canonical baseline:"
  echo "$DIFF_OUTPUT"
  exit 1
else
  echo "✅ LICENSE.md matches the canonical baseline."
fi

echo "✅ All validations passed."
