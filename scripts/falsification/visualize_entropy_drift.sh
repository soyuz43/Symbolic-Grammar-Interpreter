#!/bin/bash

# visualize_entropy_drift.sh — Mermaid diagram of drift across generations
# Usage: ./scripts/falsification/visualize_entropy_drift.sh <artifact|system> <name>

set -o errexit
set -o nounset
set -o pipefail

TYPE="$1" # artifact or system
NAME="$2"

BASE_DIR="philosophy/entropy_index/$TYPE"
OUT="drift_graph_${NAME}.mmd"

cat > "$OUT" <<EOF
%% Drift Graph for $TYPE:$NAME
graph TD
EOF

prev=""
for dir in $(find "$BASE_DIR" -type d -name "gen*_${NAME}" | sort -V); do
  manifest="$dir/input_manifest.txt"

  # Domain validation
  if [[ "$TYPE" == "artifact" && $(grep -c 'FSM Role:' "$manifest") -gt 0 ]]; then
    echo "❌ Artifact visualization attempting to draw from FSM manifest: $dir" >&2
    exit 1
  fi

  if [[ "$TYPE" == "system" && $(grep -c 'Artifact:' "$manifest") -gt 0 ]]; then
    echo "❌ System visualization attempting to draw from artifact manifest: $dir" >&2
    exit 1
  fi

  gen=$(basename "$dir" | cut -d_ -f1)
  tension=$(grep -oP 'Tension: δ\K[0-9.]+' "$manifest" || echo "?")
  weight=$(grep -oP 'FSM_WEIGHT: \K[0-9.]+' "$manifest" || echo "?")
  collapse=$(grep -oP 'Collapse_Log: \K[0-9]+' "$manifest" || echo "?")
  delta=$(<"$dir/delta_entropy.txt" 2>/dev/null || echo "0")

  echo "$gen_${NAME}[\"$gen\\nδ$tension\\nW:$weight\\nC:$collapse\"]" >> "$OUT"

  if [[ -n "$prev" ]]; then
    echo "$prev -->|Δ${delta}| $gen_${NAME}" >> "$OUT"
  fi

  prev="$gen_${NAME}"
done

echo
echo "✅ Mermaid graph generated: $OUT"
echo "Use \`mmdc -i $OUT -o ${OUT%.mmd}.png\` to render."
