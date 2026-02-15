#!/bin/bash

# mutate_artifact.sh — Deterministic mutation of rhetorical artifacts under contradiction pressure
# Usage:
#   Interactive: ./mutate_artifact.sh <artifact> <prev_gen> <new_gen> [--pressure <yaml>]
#   Deterministic: ./mutate_artifact.sh <artifact> <prev_gen> <new_gen> --meta <file> [--pressure <yaml>]

set -o errexit
set -o nounset
set -o pipefail

ARTIFACT="$1"
FROM_GEN="$2"
TO_GEN="$3"
shift 3

PHILOSOPHY_ROOT="philosophy/entropy_index/artifact"
PRESSURE=""
META_FILE=""
ALLOW_UNKNOWN="no"
OVERRIDE_PRESSURE="no"

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pressure)
      PRESSURE="$2"
      shift 2
      ;;
    --meta)
      META_FILE="$2"
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

# Normalize generation names: accept "1" → convert to "gen1"
[[ "$FROM_GEN" != gen* ]] && FROM_GEN="gen${FROM_GEN}"
[[ "$TO_GEN" != gen* ]] && TO_GEN="gen${TO_GEN}"

FROM_DIR="${PHILOSOPHY_ROOT}/${FROM_GEN}_${ARTIFACT}"
TO_DIR="${PHILOSOPHY_ROOT}/${TO_GEN}_${ARTIFACT}"

# Guards
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

# Load metadata deterministic (.meta) or interactive
if [[ -n "$META_FILE" ]]; then
  if [[ ! -f "$META_FILE" ]]; then
    printf "❌ Metadata file not found: %s\n" "$META_FILE" >&2
    exit 1
  fi
  printf "⚙️  Loading deterministic mutation metadata from: %s\n" "$META_FILE"
  WEIGHT=$(grep -m1 '^FSM_WEIGHT=' "$META_FILE" | cut -d= -f2)
  TENSION=$(grep -m1 '^TENSION=' "$META_FILE" | cut -d= -f2)
  COLLAPSE=$(grep -m1 '^COLLAPSE=' "$META_FILE" | cut -d= -f2)
  
  if [[ -z "$WEIGHT" || -z "$TENSION" || -z "$COLLAPSE" ]]; then
    printf "❌ ERROR: %s missing required keys (FSM_WEIGHT, TENSION, COLLAPSE)\n" "$META_FILE" >&2
    exit 1
  fi
else
  printf "🔍 Previous Manifest:\n"
  cat "$FROM_DIR/input_manifest.txt"
  printf "\n🧠 Input new epistemic values for %s:\n" "$TO_GEN"
  read -rp "FSM_WEIGHT (0.0–1.0): " WEIGHT
  read -rp "Tension (δ): " TENSION
  read -rp "Collapse_Log (integer): " COLLAPSE
  
  # Offer to save metadata
  read -rp "Save metadata to ${ARTIFACT}.${FROM_GEN}-to-${TO_GEN}.meta? (y/n): " save
  if [[ "${save:-n}" =~ ^[Yy]$ ]]; then
    META_SAVE="${ARTIFACT}.${FROM_GEN}-to-${TO_GEN}.meta"
    cat > "$META_SAVE" <<EOF
# Mutation meta ${FROM_GEN}_${ARTIFACT} → ${TO_GEN}_${ARTIFACT}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
FSM_WEIGHT=$WEIGHT
TENSION=$TENSION
COLLAPSE=$COLLAPSE
EOF
    printf "💾 Metadata saved to %s\n" "$META_SAVE"
  fi
fi

# Validate inputs
if ! awk "BEGIN{exit !($WEIGHT >= 0 && $WEIGHT <= 1)}"; then
  printf "❌ Invalid FSM_WEIGHT\n" >&2
  exit 1
fi

if ! awk "BEGIN{exit !(($TENSION ~ /^[0-9.]+$/) && $TENSION >= 0)}"; then
  printf "❌ Invalid Tension value\n" >&2
  exit 1
fi

if ! [[ "$COLLAPSE" =~ ^[0-9]+$ ]]; then
  printf "❌ Collapse_Log must be integer\n" >&2
  exit 1
fi

# Copy raw artifact
if [[ -f "$FROM_DIR/raw_artifact.md" ]]; then
  cp "$FROM_DIR/raw_artifact.md" "$TO_DIR/raw_artifact.md"
fi

# Process pressure YAML if provided
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

  printf "🔬 Validating contradiction impact from %s...\n" "$PRESSURE"
  
  total_weight=0
  contradiction_count=0
  unknown_types=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Extract contradiction type
    if [[ "$line" == *"type:"* ]]; then
      ctype=$(echo "$line" | sed -n 's/.*type:[[:space:]]*\([^,}]*\).*/\1/p' | tr -d '"')
      [[ -z "$ctype" ]] && continue
      ((contradiction_count++))
      
      if [[ ! -f "philosophy/contradictions/typologies/${ctype}.yaml" ]]; then
        if [[ "$ALLOW_UNKNOWN" == "yes" ]]; then
          unknown_types+=("$ctype")
        else
          printf "❌ Unknown contradiction type: %s\n" "$ctype" >&2
          exit 1
        fi
      fi
    fi
    
    # Extract confidence
    if [[ "$line" =~ confidence:[[:space:]]*([0-9.]+) ]]; then
      conf="${BASH_REMATCH[1]}"
      total_weight=$(awk -v total="$total_weight" -v add="$conf" 'BEGIN { printf "%.4f", total + add }')
    fi
  done < "$PRESSURE"

  avg_weight="0"
  if (( contradiction_count > 0 )); then
    avg_weight=$(awk -v sum="$total_weight" -v count="$contradiction_count" 'BEGIN { printf "%.2f", sum / count }')
  fi

  expected_collapse=$(( contradiction_count > 4 ? 3 : (contradiction_count > 2 ? 2 : 1) ))
  min_tension=$(awk -v a="$avg_weight" 'BEGIN { printf "%.2f", a * 0.9 + 0.3 }')

  printf "📊 Contradictions: %s\n📈 Avg. confidence: %s\n" "$contradiction_count" "$avg_weight"

  if (( COLLAPSE < expected_collapse )) && [[ "$OVERRIDE_PRESSURE" != "yes" ]]; then
    printf "❌ ERROR: Collapse_Log (%s) below expected (%s)\n" "$COLLAPSE" "$expected_collapse" >&2
    exit 1
  fi

  if awk "BEGIN{exit !($TENSION < $min_tension)}" && [[ "$OVERRIDE_PRESSURE" != "yes" ]]; then
    printf "❌ ERROR: Tension (δ%s) below recommended minimum (δ%s)\n" "$TENSION" "$min_tension" >&2
    exit 1
  fi

  cp "$PRESSURE" "$TO_DIR/contradictions.yaml"
fi

# Write Manifest
cat > "$TO_DIR/input_manifest.txt" <<EOF
# Artifact: $ARTIFACT
# Generation: $TO_GEN
# Tension: δ$TENSION

FSM_WEIGHT: $WEIGHT
Collapse_Log: $COLLAPSE
EOF

# Entropy hash
normalize_manifest() {
  grep -E '^(FSM_WEIGHT|Collapse_Log)' "$1" | sed 's/ //g' | LC_ALL=C sort
}

hash_entropy() {
  normalize_manifest "$1" | sha256sum | awk '{print $1}'
}

hash_entropy "$TO_DIR/input_manifest.txt" > "$TO_DIR/entropy_value.txt"

from_hash=$(<"$FROM_DIR/entropy_value.txt")
to_hash=$(<"$TO_DIR/entropy_value.txt")

# Hamming distance
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

- FSM Weight: $prev_weight → $WEIGHT
- Collapse Count: $prev_collapse → $COLLAPSE
- ΔEntropy (Hamming): $delta_entropy bits
EOF

# Interpretation
cat > "$TO_DIR/interpretation.md" <<EOF
## Artifact Mutation: $ARTIFACT

### Generation: $TO_GEN (from $FROM_GEN)
- FSM Weight: $WEIGHT
- Tension: δ$TENSION
- Collapse Events: $COLLAPSE

### Drift Analysis
- ΔEntropy: $delta_entropy bits
- FSM Weight: $prev_weight → $WEIGHT
- Collapse Log: $prev_collapse → $COLLAPSE
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
printf "🔑 Entropy fingerprint: %s\n" "$to_hash"
printf "📊 ΔEntropy (Hamming): %s bits\n" "$delta_entropy"
