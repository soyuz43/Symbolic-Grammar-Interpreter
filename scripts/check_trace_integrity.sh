#!/bin/bash

# check_trace_integrity.sh — Enforces symbolic boundary constraints across all traces
# Usage: ./scripts/check_trace_integrity.sh

set -o errexit
set -o nounset
set -o pipefail

ARTIFACT_ROOT="philosophy/entropy_index/artifact"
SYSTEM_ROOT="philosophy/entropy_index/system"
BREACH_LOG="philosophy/breach/breach_logs/$(date +%Y%m%d_%H%M%S)_structural_breach.md"

touch "$BREACH_LOG"

log_breach() {
  local msg="$1"
  local hash="$2"
  {
    echo "## Structural Violation Detected"
    echo "- Message: $msg"
    echo "- Trace Hash: \`$hash\`"
    echo "- Timestamp: $(date -u)"
  } >> "$BREACH_LOG"
}

hash_trace_dir() {
  local dir="$1"
  find "$dir" -type f -exec sha256sum {} \; | sha256sum | awk '{print $1}'
}

validate_trace_dir() {
  local path="$1"
  local domain="$2" # "artifact" or "system"
  local base=$(basename "$path")
  local gen="${base%%_*}"
  local id="${base#*_}"

  local manifest="$path/input_manifest.txt"

  if [[ ! -f "$manifest" ]]; then
    echo "❌ Missing manifest: $path"
    log_breach "Missing manifest for $path" "N/A"
    return
  fi

  # Basic field check
  local fsm tension collapse
  fsm=$(grep -E 'FSM_WEIGHT' "$manifest" | awk '{print $2}' || true)
  tension=$(grep -E 'Tension' "$manifest" | sed 's/[^0-9.]//g' || true)
  collapse=$(grep -E 'Collapse_Log' "$manifest" | awk '{print $2}' || true)

  if [[ -z "$fsm" || -z "$tension" || -z "$collapse" ]]; then
    echo "❌ Manifest field missing in $path"
    log_breach "Incomplete manifest fields: $path" "$(hash_trace_dir "$path")"
    return
  fi

  # Epistemic boundary validation
  if [[ "$domain" == "artifact" && "$id" =~ ^(ideational|interpersonal|textual)$ ]]; then
    echo "❌ FSM name found in artifact domain: $id"
    log_breach "FSM role misencoded in artifact domain: $id" "$(hash_trace_dir "$path")"
  fi

  if [[ "$domain" == "system" && "$id" =~ ^tau_.* ]]; then
    echo "❌ Rhetorical construct found in system domain: $id"
    log_breach "Rhetorical operator misencoded in system domain: $id" "$(hash_trace_dir "$path")"
  fi

  # Gen lineage check
  if [[ "$gen" =~ gen([2-9][0-9]*) ]]; then
    local prev=$(( ${BASH_REMATCH[1]} - 1 ))
    local prev_dir=$(dirname "$path")/gen${prev}_${id}
    if [[ ! -d "$prev_dir" ]]; then
      echo "❌ Missing previous generation for $path"
      log_breach "Invalid generational lineage for $path" "$(hash_trace_dir "$path")"
    fi
  fi

  echo "✅ Verified: $path"
}

scan_all_traces() {
  local root="$1"
  local domain="$2"

  echo "🔍 Scanning $domain domain: $root"
  find "$root" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    validate_trace_dir "$dir" "$domain"
  done
}

main() {
  echo "🚦 Beginning structural trace integrity scan..."

  scan_all_traces "$ARTIFACT_ROOT" "artifact"
  scan_all_traces "$SYSTEM_ROOT" "system"

  echo
  echo "📄 Breach log recorded at: $BREACH_LOG"
}

main
