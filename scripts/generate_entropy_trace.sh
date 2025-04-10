#!/bin/bash

# generate_entropy_trace.sh — Recursive Epistemic Drift Tracker for FSM Roles
# Encodes symbolic state of FSM roles (e.g. ideational) as falsifiable epistemic traces
# Domain: philosophy/entropy_index/system/
#
# Usage:
#   ./generate_entropy_trace.sh <role> <gen> <tension> [--compare <prev_gen>]

set -o errexit
set -o nounset
set -o pipefail

PHILOSOPHY_ROOT="philosophy/entropy_index/system"
FSM_PATH="semiotic_engine/src/fsm"

if [[ "$PHILOSOPHY_ROOT" =~ /artifact(/|$) ]]; then
  echo "❌ ERROR: Refusing to write into artifact namespace. Use encode_artifact.sh instead." >&2
  exit 1
fi

validate_inputs() {
  local role="$1"
  local gen="$2"
  local tension="$3"

  if [[ "$role" =~ ^tau_.* || "$role" =~ .*manifesto.* ]]; then
    echo "❌ ERROR: This appears to be a rhetorical artifact. Use encode_artifact.sh." >&2
    return 1
  fi

  if [[ ! "$role" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid role format: $role" >&2
    return 1
  fi

  if [[ ! "$gen" =~ ^gen[0-9]+$ ]]; then
    echo "Invalid generation identifier: $gen" >&2
    return 1
  fi

  if [[ ! "$tension" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Tension must be a number: $tension" >&2
    return 1
  fi

  return 0
}

extract_fsm_weight() {
  local role="$1"
  local fsm_file="$FSM_PATH/${role}.py"

  if [[ ! -f "$fsm_file" ]]; then
    echo "FSM file not found: $fsm_file" >&2
    return 1
  fi

  local weight
  weight=$(grep -Eo '[0-9]+\.[0-9]+' "$fsm_file" | head -1)

  if [[ -z "$weight" ]]; then
    echo "FSM weight not found in $fsm_file" >&2
    return 1
  fi

  echo "$weight"
}

count_collapse_logs() {
  local gen="$1"
  local log_file="philosophy/dialectical_cores/${gen}_paradox_log.md"

  if [[ ! -f "$log_file" ]]; then
    echo "Collapse log not found: $log_file" >&2
    return 1
  fi

  grep -c 'Collapse' "$log_file"
}

normalize_manifest() {
  grep -E '^(FSM_WEIGHT|Collapse_Log|Tension)' "$1" | sed 's/ //g' | LC_ALL=C sort
}

generate_entropy() {
  local file="$1"
  normalize_manifest "$file" | sha256sum | awk '{print $1}'
}

compute_hamming_distance() {
  local h1="$1" h2="$2"
  local b1 b2 hamming=0

  b1=$(xxd -r -p <<< "$h1" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')
  b2=$(xxd -r -p <<< "$h2" | xxd -b -c 32 | awk '{for(i=2;i<=NF;i++) printf $i}')
  for ((i=0; i<${#b1}; i++)); do
    [[ "${b1:$i:1}" != "${b2:$i:1}" ]] && ((hamming++))
  done

  echo "$hamming"
}

create_input_manifest() {
  local dir="$1" role="$2" gen="$3" tension="$4" weight="$5" collapse="$6"

  cat > "$dir/input_manifest.txt" <<EOF
# FSM Role: $role
# Generation: $gen
# Tension: δ$tension

FSM_WEIGHT: $weight
Collapse_Log: $collapse

# Hash Method: SHA-256 over normalized FSM_WEIGHT, Collapse_Log, Tension
EOF
}

write_interpretation() {
  local dir="$1" role="$2" gen="$3" tension="$4" entropy="$5"

  cat > "$dir/interpretation.md" <<EOF
## Entropy Trace: $gen – $role

### Pseudo-Entropy Value:
\`$entropy\`

### Interpretation:
This entropy value reflects symbolic state under recursive pressure at δ$tension.

It encodes formal FSM configuration (weight) and contradiction exposure (collapse log) for role '$role' in generation '$gen'.

### Methodology:
- Manifest: \`input_manifest.txt\`
- Hash: Normalized + reproducible
- Used for: Δentropy drift, mutation tracking, collapse forecasting
EOF
}

compare_generations() {
  local dir="$1" role="$2" gen="$3" prev="$4"

  local prev_dir="$PHILOSOPHY_ROOT/${prev}_${role}"
  if [[ ! -f "$prev_dir/entropy_value.txt" || ! -f "$prev_dir/input_manifest.txt" ]]; then
    echo "❌ Cannot compare: missing previous generation at $prev_dir" >&2
    return 1
  fi

  local prev_hash=$(<"$prev_dir/entropy_value.txt")
  local this_hash=$(<"$dir/entropy_value.txt")
  local delta
  delta=$(compute_hamming_distance "$this_hash" "$prev_hash")

  echo "$delta" > "$dir/delta_entropy.txt"

  local w1=$(grep FSM_WEIGHT "$prev_dir/input_manifest.txt" | awk '{print $2}')
  local c1=$(grep Collapse_Log "$prev_dir/input_manifest.txt" | awk '{print $2}')
  local w2=$(grep FSM_WEIGHT "$dir/input_manifest.txt" | awk '{print $2}')
  local c2=$(grep Collapse_Log "$dir/input_manifest.txt" | awk '{print $2}')

  cat > "$dir/entropy_diff_manifest.md" <<EOF
## Drift Comparison: $prev → $gen

- FSM Weight: $w1 → $w2
- Collapse Count: $c1 → $c2
- ΔEntropy (Hamming): $delta bits
EOF

  cat >> "$dir/interpretation.md" <<EOF

### Drift Comparison with $prev
- ΔEntropy: $delta bits
- FSM Weight: $w1 → $w2
- Collapse Log: $c1 → $c2
EOF
}

main() {
  local role="$1"
  local gen="$2"
  local tension="$3"
  local compare_mode="no"
  local prev_gen=""

  if [[ "${4:-}" == "--compare" ]]; then
    [[ -n "${5:-}" ]] || { echo "Missing argument for --compare" >&2; exit 1; }
    compare_mode="yes"
    prev_gen="$5"
  fi

  validate_inputs "$role" "$gen" "$tension"

  local dir="$PHILOSOPHY_ROOT/${gen}_${role}"
  [[ -d "$dir" ]] && { echo "❌ ERROR: $dir already exists. Use next generation." >&2; exit 1; }
  mkdir -p "$dir"

  local weight collapse
  weight=$(extract_fsm_weight "$role")
  collapse=$(count_collapse_logs "$gen")

  create_input_manifest "$dir" "$role" "$gen" "$tension" "$weight" "$collapse"

  local entropy
  entropy=$(generate_entropy "$dir/input_manifest.txt")
  echo "$entropy" > "$dir/entropy_value.txt"

  write_interpretation "$dir" "$role" "$gen" "$tension" "$entropy"

  if [[ "$compare_mode" == "yes" ]]; then
    compare_generations "$dir" "$role" "$gen" "$prev_gen"
  fi

  echo "✅ Trace generated: $dir"
}

main "$@"
