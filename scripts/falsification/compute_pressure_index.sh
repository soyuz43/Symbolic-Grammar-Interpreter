#!/bin/bash

# compute_pressure_index.sh — Analyzes contradictions.yaml for pressure modeling
# Usage: ./scripts/falsification/compute_pressure_index.sh <contradictions.yaml>

set -o errexit
set -o nounset
set -o pipefail

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  printf "❌ File not found: %s\n" "$FILE" >&2
  exit 1
fi

# === Extract confidence values from YAML
mapfile -t confidences < <(grep -oE 'confidence:[[:space:]]*[0-9]+\.[0-9]+' "$FILE" | awk '{print $2}')

if (( ${#confidences[@]} == 0 )); then
  printf "❌ No confidence values found in: %s\n" "$FILE" >&2
  exit 1
fi

# === Compute mean
sum=0
for conf in "${confidences[@]}"; do
  sum=$(awk -v s="$sum" -v c="$conf" 'BEGIN { printf "%.6f", s + c }')
done

count=${#confidences[@]}
mean=$(awk -v s="$sum" -v c="$count" 'BEGIN { printf "%.4f", s / c }')

# === Compute variance
var_sum=0
for conf in "${confidences[@]}"; do
  var_sum=$(awk -v v="$var_sum" -v c="$conf" -v m="$mean" 'BEGIN { d = c - m; printf "%.6f", v + (d * d) }')
done
variance=$(awk -v vs="$var_sum" -v c="$count" 'BEGIN { printf "%.4f", vs / c }')

# === Compute Pressure Index
pressure_index=$(awk -v mean="$mean" -v var="$variance" -v count="$count" 'BEGIN { printf "%.4f", (count * mean) + (10 * var) }')

# === Derive recommended metrics
recommended_tension=$(awk -v p="$pressure_index" 'BEGIN { printf "δ%.2f", (p / 1.4) }')
recommended_collapse=$(( count > 6 ? 5 : count > 3 ? 3 : 1 ))

# === Output
printf "🧠 Contradiction Analysis: %s\n" "$FILE"
printf "----------------------------------\n"
printf "Contradiction count     : %d\n" "$count"
printf "Mean confidence         : %.2f\n" "$mean"
printf "Confidence variance     : %.2f\n" "$variance"
printf "📊 Pressure Index        : %.2f\n" "$pressure_index"
printf "⚖️  Suggested δTension   : %s\n" "$recommended_tension"
printf "🔥 Min Collapse_Log      : %d\n" "$recommended_collapse"

# Optional structured export
if [[ "${2:-}" == "--export" ]]; then
  export_path="${FILE%.yaml}_pressure.json"
  cat > "$export_path" <<EOF
{
  "pressure_index": $pressure_index,
  "mean_confidence": $mean,
  "variance": $variance,
  "contradiction_count": $count,
  "recommended_tension": "$recommended_tension",
  "recommended_collapse_log": $recommended_collapse
}
EOF
  printf "📄 JSON export: %s\n" "$export_path"
fi
