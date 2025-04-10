#!/bin/bash

# scan_unencoded_artifacts.sh — Epistemic Intake Manager
# Moves unexamined literary artifacts to holding quarantine
# Prepares for formal encoding via encode_artifact.sh

set -o errexit
set -o nounset
set -o pipefail

RAW_DIR="philosophy/artifacts/literary_ideas"
HOLD_DIR="philosophy/quarantine/holding_patterns"
INDEX_DIR="philosophy/entropy_index"

mkdir -p "$HOLD_DIR"

shopt -s nullglob
declare -a candidates=()

# === Scan for unencoded artifacts ===
for file in "$RAW_DIR"/*.md "$RAW_DIR"/*.txt; do
  base=$(basename "$file")
  artifact_name="${base%.*}"
  gen1_dir="$INDEX_DIR/gen1_${artifact_name}"

  if [[ ! -d "$gen1_dir" && ! -f "$HOLD_DIR/$base" ]]; then
    candidates+=("$file")
  fi
done

if [[ "${#candidates[@]}" -eq 0 ]]; then
  printf "✅ No unprocessed literary artifacts remain.\n"
  exit 0
fi

# === Present user with pending candidates ===
printf "\n🔍 %d unexamined artifact(s) found in %s:\n\n" "${#candidates[@]}" "$RAW_DIR"
for i in "${!candidates[@]}"; do
  printf "[%d] %s\n" "$((i+1))" "$(basename "${candidates[$i]}")"
done

echo
read -rp "Move these to quarantine/holding_patterns for later encoding? (y/n) " confirm
[[ "$confirm" != "y" ]] && exit 0

# === Move artifacts to quarantine ===
for file in "${candidates[@]}"; do
  base=$(basename "$file")
  target="$HOLD_DIR/$base"
  if [[ -f "$target" ]]; then
    printf "⚠️ Already in quarantine: %s\n" "$base"
    continue
  fi
  mv "$file" "$target"
  printf "📥 Moved → %s\n" "$target"
done

echo
printf "✅ All selected artifacts are now quarantined in: %s\n" "$HOLD_DIR"
printf "Run encode_artifact.sh on any of them to formalize their epistemic trace.\n"
