#!/bin/bash

# encode_artifact.sh — Epistemic Formalization of Rhetorical Artifacts
# Domain: philosophy/entropy_index/artifact/
# Usage: ./encode_artifact.sh <path-to-raw-artifact.md>

set -o errexit
set -o nounset
set -o pipefail

INPUT_FILE="$1"
ARTIFACT_NAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
GEN="gen1"
OUTPUT_DIR="philosophy/entropy_index/artifact/${GEN}_${ARTIFACT_NAME}"

# === Epistemic Guard: Reserved FSM roles ===
if [[ "$ARTIFACT_NAME" =~ ^(ideational|interpersonal|textual)$ ]]; then
  echo "❌ ERROR: Reserved FSM role name. Use generate_entropy_trace.sh for system components." >&2
  exit 1
fi

# === Epistemic Guard: Existing FSM file conflict ===
FSM_PATH="semiotic_engine/src/fsm"
if [[ -f "$FSM_PATH/${ARTIFACT_NAME}.py" ]]; then
  echo "❌ ERROR: '$ARTIFACT_NAME' maps to an FSM role. Use generate_entropy_trace.sh instead." >&2
  exit 1
fi

# === Prevent overwrite of gen1 ===
if [[ -d "$OUTPUT_DIR" ]]; then
  echo "❌ ERROR: $OUTPUT_DIR already exists. Generation 1 is immutable." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# === Prompt for epistemic metrics ===
echo "🧬 Encoding rhetorical artifact: $INPUT_FILE → $OUTPUT_DIR"
read -rp "FSM_WEIGHT (0.0 = fluid, 1.0 = rigid): " weight
read -rp "Tension (δ scalar): " tension
read -rp "Collapse_Log (number of contradictions detected): " collapse

# === Create input_manifest.txt ===
cat > "$OUTPUT_DIR/input_manifest.txt" <<EOF
# Artifact: $ARTIFACT_NAME
# Generation: $GEN
# Tension: δ$tension

FSM_WEIGHT: $weight
Collapse_Log: $collapse

# Hash Method: SHA-256 over normalized FSM_WEIGHT, Collapse_Log, Tension
EOF

# === Normalize manifest + hash ===
normalize_manifest() {
  grep -E '^(FSM_WEIGHT|Collapse_Log|Tension)' "$1" | sed 's/ //g' | LC_ALL=C sort
}

generate_entropy() {
  normalize_manifest "$1" | sha256sum | awk '{print $1}'
}

entropy=$(generate_entropy "$OUTPUT_DIR/input_manifest.txt")
echo "$entropy" > "$OUTPUT_DIR/entropy_value.txt"

# === Write interpretation.md ===
cat > "$OUTPUT_DIR/interpretation.md" <<EOF
## Artifact Trace: $ARTIFACT_NAME — Generation 1

### Epistemic Metrics
- FSM_WEIGHT: $weight
- Collapse_Log: $collapse
- Tension: δ$tension

### Entropy Fingerprint
\`$entropy\`

### Commentary
This rhetorical artifact has been formally encoded as a symbolic trace. Its epistemic shape is determined by:
- Structural rigidity (FSM_WEIGHT)
- Internal contradiction load (Collapse_Log)
- Interpretive instability (δTension)

This is the foundational generation (gen1) for recursive analysis. Drift and transformation must now be measured as symbolic mutation over future generations.
EOF

# === Preserve raw source ===
cp "$INPUT_FILE" "$OUTPUT_DIR/raw_artifact.md"
echo "🧾 Raw artifact preserved as: $OUTPUT_DIR/raw_artifact.md"

# === Done ===
echo "✅ Artifact successfully encoded: $OUTPUT_DIR"
