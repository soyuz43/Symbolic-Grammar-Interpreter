#!/bin/bash

# validate_topography.sh — Epistemic Drift Topography Validator
# Validates that visualized Δentropy reflects falsifiable symbolic state change.

set -o errexit
set -o nounset
set -o pipefail

ENTROPY_DIR="philosophy/entropy_index"
TOPOLOGY_FILE="$ENTROPY_DIR/topography.mmd"
TMP_HASH_DIR="/tmp/normalized_entropy_traces"
errors=0

# Normalize manifest content
normalize_manifest() {
  local file="$1"
  grep -E '^(FSM_WEIGHT|Collapse_Log|Tension)' "$file" \
    | sed 's/ //g' \
    | LC_ALL=C sort
}

# Compute SHA256 hash of normalized structure
hash_normalized_manifest() {
  local file="$1"
  normalize_manifest "$file" | sha256sum | awk '{print $1}'
}

# Compute bitwise delta
hamming_distance() {
  local h1="$1" h2="$2"
  local b1 b2 delta=0

  b1=$(xxd -r -p <<< "$h1" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')
  b2=$(xxd -r -p <<< "$h2" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')

  for ((i=0; i<${#b1}; i++)); do
    [[ "${b1:$i:1}" != "${b2:$i:1}" ]] && ((delta++))
  done

  echo "$delta"
}

# === Step 1: Parse Mermaid edges and check Δentropy ===
echo "🔍 Validating drift consistency from $TOPOLOGY_FILE"
declare -A hashes
declare -A generations

while IFS= read -r line; do
  # Skip non-edge lines
  [[ "$line" =~ --> ]] || continue

  src=$(echo "$line" | awk '{print $1}')
  dst=$(echo "$line" | awk '{print $NF}')
  declared_delta=$(echo "$line" | grep -oP 'Δ\K[0-9]+')

  for node in "$src" "$dst"; do
    dir="$ENTROPY_DIR/${node}"
    manifest="$dir/input_manifest.txt"

    if [[ ! -f "$manifest" ]]; then
      echo "❌ MISSING MANIFEST: $manifest"
      ((errors++))
      continue
    fi

    # Cache hash if missing
    if [[ -z "${hashes[$node]:-}" ]]; then
      hashes[$node]=$(hash_normalized_manifest "$manifest")
    fi

    # Check generation ordering
    gen_num=$(echo "$node" | grep -oP '^gen\K[0-9]+')
    role=$(echo "$node" | cut -d'_' -f2)
    if [[ -n "${generations[$role]:-}" ]] && (( gen_num <= generations[$role] )); then
      echo "❌ Non-monotonic generation for $role: $gen_num <= ${generations[$role]}"
      ((errors++))
    fi
    generations[$role]=$gen_num
  done

  # Compare hashes
  actual_delta=$(hamming_distance "${hashes[$src]}" "${hashes[$dst]}")
  if [[ "$actual_delta" -ne "$declared_delta" ]]; then
    echo "❌ Drift mismatch: $src → $dst claims Δ$declared_delta but actual is Δ$actual_delta"
    ((errors++))
  else
    echo "✔ Drift validated: $src → $dst (Δ$actual_delta)"
  fi
done < "$TOPOLOGY_FILE"

# === Step 2: Check for phantom drift ===
for role_dir in "$ENTROPY_DIR"/gen*_*/; do
  base=$(basename "$role_dir")
  manifest="$role_dir/input_manifest.txt"

  # Hash file must exist
  recomputed_hash=$(hash_normalized_manifest "$manifest")
  stored_path="$TMP_HASH_DIR/${base}.hash"

  if [[ ! -f "$stored_path" ]]; then
    echo "❌ Missing stored hash for $base"
    ((errors++))
    continue
  fi

  stored_hash=$(<"$stored_path")
  if [[ "$recomputed_hash" != "$stored_hash" ]]; then
    echo "❌ Hash mismatch in $base: stored vs recomputed"
    ((errors++))
  else
    echo "✔ Hash match: $base"
  fi
done

# === Summary ===
echo ""
if (( errors == 0 )); then
  echo "✅ Topography VALID: all Δentropy, ordering, and hash links are semantically consistent."
else
  echo "❌ Topography INVALID: $errors epistemic inconsistency$( (( errors > 1 )) && echo 'ies' || echo 'y' ) found."
  exit 1
fi
