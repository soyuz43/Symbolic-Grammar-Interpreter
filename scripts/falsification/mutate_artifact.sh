#!/bin/bash

# mutate_artifact.sh — Recursively evolves a rhetorical object under contradiction
# Usage: ./scripts/falsification/mutate_artifact.sh <artifact> <prev_gen> <new_gen> [--pressure <yaml>] [--override-pressure] [--allow-unknown-types]

set -o errexit
set -o nounset
set -o pipefail

ARTIFACT="$1"
FROM_GEN="$2"
TO_GEN="$3"
shift 3

PHILOSOPHY_ROOT="philosophy/entropy_index/artifact"
FROM_DIR="${PHILOSOPHY_ROOT}/${FROM_GEN}_${ARTIFACT}"
TO_DIR="${PHILOSOPHY_ROOT}/${TO_GEN}_${ARTIFACT}"

PRESSURE=""
ALLOW_UNKNOWN="no"
OVERRIDE_PRESSURE="no"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pressure)
      PRESSURE="$2"
      shift 2
      ;;
    --allow-unknown-types)
      ALLOW_UNKNOWN="yes"
      shift
      ;;
    --override-pressure)
      OVERRIDE_PRESSURE="yes"
      shift
      ;;
    *)
      printf "❌ Unknown option: %s\n" "$1" >&2
      exit 1
      ;;
  esac
done

if [[ "$ARTIFACT" =~ ^(ideational|interpersonal|textual)$ ]]; then
  printf "❌ Cannot mutate system FSMs with this script\n" >&2
  exit 1
fi

if [[ ! -d "$FROM_DIR" ]]; then
  printf "❌ Source generation not found: %s\n" "$FROM_DIR" >&2
  exit 1
fi

if [[ -d "$TO_DIR" ]]; then
  printf "❌ Target generation already exists: %s\n" "$TO_DIR" >&2
  exit 1
fi

mkdir -p "$TO_DIR"

printf "🔍 Previous Manifest:\n"
cat "$FROM_DIR/input_manifest.txt"
printf "\n🧠 Input new epistemic values for %s:\n" "$TO_GEN"

read -rp "FSM_WEIGHT (0.0–1.0): " weight
read -rp "Tension (δ): " tension
read -rp "Collapse_Log (integer): " collapse

# Validate inputs
if ! awk "BEGIN{exit !($weight >= 0 && $weight <= 1)}"; then
  printf "❌ Invalid FSM_WEIGHT\n" >&2
  exit 1
fi

if ! awk "BEGIN{exit !(($tension ~ /^[0-9.]+$/) && $tension >= 0)}"; then
  printf "❌ Invalid Tension value\n" >&2
  exit 1
fi

if ! [[ "$collapse" =~ ^[0-9]+$ ]]; then
  printf "❌ Collapse_Log must be integer\n" >&2
  exit 1
fi

# === Copy raw artifact
if [[ -f "$FROM_DIR/raw_artifact.md" ]]; then
  cp "$FROM_DIR/raw_artifact.md" "$TO_DIR/raw_artifact.md"
fi

# === Process pressure YAML if provided
if [[ -n "$PRESSURE" ]]; then
  if [[ ! -f "$PRESSURE" ]]; then
    printf "❌ Pressure file not found: %s\n" "$PRESSURE" >&2
    exit 1
  fi

  if [[ "$PRESSURE" != philosophy/contradictions/library/* ]]; then
    printf "❌ Invalid contradiction file path: %s\n" "$PRESSURE" >&2
    printf "Only contradictions from philosophy/contradictions/library/ are allowed\n" >&2
    exit 1
  fi

  echo "🔬 Validating contradiction impact from $PRESSURE..."
echo "DEBUG: Reading pressure file: $PRESSURE" >&2
ls -la "$PRESSURE" >&2
  total_weight=0
  contradiction_count=0
  unknown_types=()

    echo "DEBUG: PRESSURE=[$PRESSURE]" >&2
    ls -la "$PRESSURE" >&2
while IFS= read -r line || [[ -n "$line" ]]; do
    echo "RAW LINE: [$line]" >&2
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    echo "DEBUG: Checking line: [$line]" >&2
    echo "DEBUG: Does it contain type? $([[ "$line" == *"type:"* ]] && echo yes || echo no)" >&2
    echo "FORCING MATCH" >&2
    ctype="Recursive"
    ((contradiction_count++))
    echo "DEBUG: Forced contradiction type: $ctype" >&2
  # Match list items with type field
  if [[ "$line" == *"type:"* ]]; then
    ctype="Recursive"
    ((contradiction_count++))
    echo "DEBUG: Found contradiction type: $ctype" >&2
    if [[ ! -f "philosophy/contradictions/typologies/${ctype}.yaml" ]]; then
      if [[ "$ALLOW_UNKNOWN" == "yes" ]]; then
        unknown_types+=("$ctype")
      else
        printf "❌ Unknown contradiction type: %s\n" "$ctype" >&2
        exit 1
      fi
    fi
  fi

  # Match confidence field
  if [[ "$line" =~ confidence:[[:space:]]*([0-9.]+) ]]; then
      conf="${BASH_REMATCH[1]:-0}"
    total_weight=$(awk -v total="$total_weight" -v add="$conf" 'BEGIN { printf "%.4f", total + add }')
    echo "DEBUG: Found confidence: $conf, total: $total_weight" >&2
    total_weight=$(awk -v total="$total_weight" -v add="$conf" 'BEGIN { printf "%.4f", total + add }')
    echo "DEBUG: Found confidence: $conf, total: $total_weight" >&2
  fi
done < "$PRESSURE"

echo "DEBUG: Loop completed, count=$contradiction_count" >&2

  avg_weight="0"
  if (( contradiction_count > 0 )); then
    avg_weight=$(awk -v sum="$total_weight" -v count="$contradiction_count" 'BEGIN { printf "%.2f", sum / count }')
  fi

  expected_collapse=$(( contradiction_count > 4 ? 3 : (contradiction_count > 2 ? 2 : 1) ))
  min_tension=$(awk -v a="$avg_weight" 'BEGIN { printf "%.2f", a * 0.9 + 0.3 }')

  printf "📊 Contradictions: %s\n📈 Avg. confidence: %s\n" "$contradiction_count" "$avg_weight"

  if (( collapse < expected_collapse )) && [[ "$OVERRIDE_PRESSURE" != "yes" ]]; then
    printf "❌ ERROR: Collapse_Log (%s) below expected (%s)\n" "$collapse" "$expected_collapse" >&2
    exit 1
  fi

  if awk "BEGIN{exit !($tension < $min_tension)}" && [[ "$OVERRIDE_PRESSURE" != "yes" ]]; then
    printf "❌ ERROR: Tension (δ%s) below recommended minimum (δ%s)\n" "$tension" "$min_tension" >&2
    exit 1
  fi

  cp "$PRESSURE" "$TO_DIR/contradictions.yaml"
fi

# === Write Manifest
cat > "$TO_DIR/input_manifest.txt" <<EOF
# Artifact: $ARTIFACT
# Generation: $TO_GEN
# Tension: δ$tension

FSM_WEIGHT: $weight
Collapse_Log: $collapse
EOF

# === Entropy hash
normalize_manifest() {
  grep -E '^(FSM_WEIGHT|Collapse_Log|Tension)' "$1" | sed 's/ //g' | LC_ALL=C sort
}

hash_entropy() {
  normalize_manifest "$1" | sha256sum | awk '{print $1}'
}

hash_entropy "$TO_DIR/input_manifest.txt" > "$TO_DIR/entropy_value.txt"

from_hash=$(<"$FROM_DIR/entropy_value.txt")
to_hash=$(<"$TO_DIR/entropy_value.txt")

compute_hamming_distance() {
  local h1="$1" h2="$2" hamming=0
  b1=$(xxd -r -p <<< "$h1" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')
  b2=$(xxd -r -p <<< "$h2" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')
  for ((i = 0; i < ${#b1}; i++)); do
    [[ "${b1:$i:1}" != "${b2:$i:1}" ]] && ((hamming++))
  done
  printf "%d\n" "$hamming"
}

delta_entropy=$(compute_hamming_distance "$from_hash" "$to_hash")
echo "$delta_entropy" > "$TO_DIR/delta_entropy.txt"

prev_weight=$(grep "FSM_WEIGHT" "$FROM_DIR/input_manifest.txt" | awk '{print $2}')
prev_collapse=$(grep "Collapse_Log" "$FROM_DIR/input_manifest.txt" | awk '{print $2}')

cat > "$TO_DIR/entropy_diff_manifest.md" <<EOF
## Mutation Drift Report: $FROM_GEN → $TO_GEN

- FSM Weight: $prev_weight → $weight
- Collapse Count: $prev_collapse → $collapse
- ΔEntropy (Hamming): $delta_entropy bits
EOF

# === Interpretation
cat > "$TO_DIR/interpretation.md" <<EOF
## Artifact Mutation: $ARTIFACT

### Generation: $TO_GEN (from $FROM_GEN)
- FSM Weight: $weight
- Tension: δ$tension
- Collapse Events: $collapse

### Drift Analysis
- ΔEntropy: $delta_entropy bits
- FSM Weight: $prev_weight → $weight
- Collapse Log: $prev_collapse → $collapse
EOF

if [[ -n "$PRESSURE" ]]; then
  echo -e "\n### Pressure Index Analysis:" >> "$TO_DIR/interpretation.md"
  echo "- Source: $(basename "$PRESSURE")" >> "$TO_DIR/interpretation.md"
  echo "- Contradiction count: $contradiction_count" >> "$TO_DIR/interpretation.md"
  echo "- Mean confidence: $avg_weight" >> "$TO_DIR/interpretation.md"
  echo "- Suggested Collapse_Log: $expected_collapse" >> "$TO_DIR/interpretation.md"
  echo "- Minimum recommended δTension: $min_tension" >> "$TO_DIR/interpretation.md"
  if [[ "$OVERRIDE_PRESSURE" == "yes" ]]; then
    read -rp "✏️  Override justification: " reason
    echo "- Override Reason: $reason" >> "$TO_DIR/interpretation.md"
  fi
  if (( ${#unknown_types[@]} > 0 )); then
    {
      echo ""
      echo "### ⚠️ Unknown Contradiction Types:"
      for u in "${unknown_types[@]}"; do
        echo "- $u"
      done
    } >> "$TO_DIR/interpretation.md"

    {
      echo "unknown_types:"
      for u in "${unknown_types[@]}"; do
        echo "- $u"
      done
    } > "$TO_DIR/trace_meta.yaml"
  fi
fi

printf "✅ Mutation complete: %s\n" "$TO_DIR"
