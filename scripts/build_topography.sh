#!/bin/bash

# ✅ Epistemically Stable: Mermaid Drift Topographer (Normalized, Falsifiable)
# Generates philosophy/entropy_index/topography.mmd

set -o errexit
set -o nounset
set -o pipefail

ENTROPY_DIR="philosophy/entropy_index"
OUTPUT_FILE="$ENTROPY_DIR/topography.mmd"
TMP_HASH_DIR="/tmp/normalized_entropy_traces"

mkdir -p "$TMP_HASH_DIR"

# Mermaid Header
cat > "$OUTPUT_FILE" <<EOF
%% Epistemic Drift Topography (Normalized + Falsification-Resilient)
graph TD
EOF

# Classify entropy drift into semiotic tension levels
color_class() {
  local delta="$1"
  if (( delta < 10 )); then echo "stable"
  elif (( delta < 50 )); then echo "warning"
  else echo "critical"
  fi
}

# Normalize manifest — extract only structural semantic lines
normalize_manifest() {
  local file="$1"
  grep -E '^(FSM_WEIGHT|Collapse_Log|Tension)' "$file" \
    | sed 's/ //g' \
    | LC_ALL=C sort
}

# Compute SHA-256 of normalized structure
hash_normalized_manifest() {
  local file="$1"
  normalize_manifest "$file" | sha256sum | awk '{print $1}'
}

# Compute Hamming distance between two SHA-256 hex hashes
hamming_distance() {
  local hash1="$1"
  local hash2="$2"
  local bin1 bin2 hamming=0

  bin1=$(xxd -r -p <<< "$hash1" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')
  bin2=$(xxd -r -p <<< "$hash2" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')

  for ((i=0; i<${#bin1}; i++)); do
    [[ "${bin1:$i:1}" != "${bin2:$i:1}" ]] && ((hamming++))
  done

  echo "$hamming"
}

# Track last node/hash per role
declare -A last_node_by_role
declare -A last_hash_by_role

# Sorted generational-role dirs
find "$ENTROPY_DIR" -maxdepth 1 -type d -name "gen*_*" | sort -V | while read -r dir; do
  gen_role=$(basename "$dir")
  gen="${gen_role%%_*}"
  role="${gen_role#*_}"
  manifest="$dir/input_manifest.txt"

  # Extract metrics
  weight=$(grep 'FSM_WEIGHT' "$manifest" | awk '{print $2}')
  tension=$(grep 'Tension' "$manifest" | sed 's/.*δ\([0-9.]*\)/\1/')
  collapse=$(grep 'Collapse_Log' "$manifest" | awk '{print $2}')

  node_id="${gen}_${role}"
  node_label="${gen}\\n${role}\\nδ${tension}\\nW:${weight}\\nC:${collapse}"

  # Normalized entropy hash
  norm_hash=$(hash_normalized_manifest "$manifest")
  echo "$norm_hash" > "$TMP_HASH_DIR/$node_id.hash"

  # Entropy drift (Δ bits) vs previous
  delta=0
  if [[ -n "${last_hash_by_role[$role]:-}" ]]; then
    delta=$(hamming_distance "$norm_hash" "${last_hash_by_role[$role]}")
  fi

  # Draw node + color classification
  class=$(color_class "$delta")
  printf "  %s[\"%s\"]:::%s\n" "$node_id" "$node_label" "$class" >> "$OUTPUT_FILE"

  # Connect edge to previous
  if [[ -n "${last_node_by_role[$role]:-}" ]]; then
    printf "  %s -->|Δ%d| %s\n" "${last_node_by_role[$role]}" "$delta" "$node_id" >> "$OUTPUT_FILE"
  fi

  # Update role-local state
  last_node_by_role["$role"]="$node_id"
  last_hash_by_role["$role"]="$norm_hash"
done

# Mermaid style legend
cat >> "$OUTPUT_FILE" <<EOF

classDef stable fill:#ccffcc,stroke:#222,stroke-width:1px,font-size:12px;
classDef warning fill:#ffffcc,stroke:#666,stroke-width:1px,font-size:12px;
classDef critical fill:#ffcccc,stroke:#900,stroke-width:2px,font-size:12px;
EOF

echo "✅ Topography generated with normalized semantics: $OUTPUT_FILE"
