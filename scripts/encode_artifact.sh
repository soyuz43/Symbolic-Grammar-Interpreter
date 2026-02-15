#!/bin/bash

# encode_artifact.sh — Deterministic epistemic formalization of rhetorical artifacts
# Domain: philosophy/entropy_index/artifact/
# Usage:
#   Interactive: ./encode_artifact.sh <artifact.md>
#   Deterministic: Create <artifact.md.meta> with FSM_WEIGHT/TENSION/COLLAPSE, then run script

set -o errexit
set -o nounset
set -o pipefail

INPUT_FILE="${1:?Usage: $0 <path-to-artifact.md>}"
ARTIFACT_NAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
GEN="gen1"
OUTPUT_DIR="philosophy/entropy_index/artifact/${GEN}_${ARTIFACT_NAME}"
METADATA_FILE="${INPUT_FILE}.meta"

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

# === Load metadata: deterministic (.meta) or interactive ===
if [[ -f "$METADATA_FILE" ]]; then
  echo "⚙️  Loading deterministic metadata from: $METADATA_FILE"
  # Strict parsing: require all three keys
  WEIGHT=$(grep -m1 '^FSM_WEIGHT=' "$METADATA_FILE" | cut -d= -f2)
  TENSION=$(grep -m1 '^TENSION=' "$METADATA_FILE" | cut -d= -f2)
  COLLAPSE=$(grep -m1 '^COLLAPSE=' "$METADATA_FILE" | cut -d= -f2)
  
  if [[ -z "$WEIGHT" || -z "$TENSION" || -z "$COLLAPSE" ]]; then
    echo "❌ ERROR: $METADATA_FILE missing required keys (FSM_WEIGHT, TENSION, COLLAPSE)" >&2
    exit 1
  fi
else
  echo "🧬 Encoding rhetorical artifact: $INPUT_FILE → $OUTPUT_DIR"
  read -rp "FSM_WEIGHT (0.0 = fluid, 1.0 = rigid): " WEIGHT
  read -rp "Tension (δ scalar): " TENSION
  read -rp "Collapse_Log (number of contradictions detected): " COLLAPSE
  
  # Offer to save for reproducibility
  read -rp "Save metadata to ${METADATA_FILE} for reproducibility? (y/n): " save
  if [[ "${save:-n}" =~ ^[Yy]$ ]]; then
    cat > "$METADATA_FILE" <<EOF
# Deterministic metadata for $INPUT_FILE
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
FSM_WEIGHT=$WEIGHT
TENSION=$TENSION
COLLAPSE=$COLLAPSE
EOF
    echo "💾 Metadata saved to $METADATA_FILE (version this file for reproducibility)"
  fi
fi

# === Create input_manifest.txt ===
cat > "$OUTPUT_DIR/input_manifest.txt" <<EOF
# Artifact: $ARTIFACT_NAME
# Generation: $GEN
# Tension: δ$TENSION

FSM_WEIGHT: $WEIGHT
Collapse_Log: $COLLAPSE

# Hash Method: SHA-256 over normalized FSM_WEIGHT, Collapse_Log, Tension
EOF

# === Normalize manifest + hash ===
normalize_manifest() {
  grep -E '^(FSM_WEIGHT|Collapse_Log)' "$1" | sed 's/ //g' | LC_ALL=C sort
}

generate_entropy() {
  normalize_manifest "$1" | sha256sum | awk '{print $1}'
}

ENTROPY=$(generate_entropy "$OUTPUT_DIR/input_manifest.txt")
echo "$ENTROPY" > "$OUTPUT_DIR/entropy_value.txt"

# === Write interpretation.md ===
cat > "$OUTPUT_DIR/interpretation.md" <<EOF
## Artifact Trace: $ARTIFACT_NAME — Generation 1

### Epistemic Metrics
- FSM_WEIGHT: $WEIGHT
- Collapse_Log: $COLLAPSE
- Tension: δ$TENSION

### Entropy Fingerprint
\`$ENTROPY\`

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
echo "🔑 Entropy fingerprint: $ENTROPY"