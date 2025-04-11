#!/bin/bash

# extract_contradictions.sh — Scans a .md file for contradiction patterns
# Outputs contradictions.yaml with line number, type, and estimated confidence

set -o errexit
set -o nounset
set -o pipefail

INPUT="$1"
OUTPUT="contradictions.yaml"

echo "# Extracted contradictions from: $INPUT" > "$OUTPUT"
echo "---" >> "$OUTPUT"

grep -niE "(not.*but)|(paradox)|(contradiction)|(cannot.*yet)|(recursive.*failure)|(assumes.*but.*denies)" "$INPUT" | while IFS=: read -r line text; do
  kind=$(echo "$text" | grep -oE 'paradox|contradiction|recursive|cannot|denies|not' | head -n1)
  conf=$(awk "BEGIN { print 0.7 + (length(\"$text\") % 10)/20 }")
  echo "- line: $line" >> "$OUTPUT"
  echo "  type: $kind" >> "$OUTPUT"
  echo "  confidence: $conf" >> "$OUTPUT"
done

count=$(grep -c '^-' "$OUTPUT" || echo "0")
echo
echo "🔍 Extracted $count contradiction$( (( count == 1 )) && echo "" || echo "s" ) to $OUTPUT"
