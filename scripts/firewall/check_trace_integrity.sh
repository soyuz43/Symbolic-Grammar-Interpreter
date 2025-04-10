#!/bin/bash

# check_trace_integrity.sh — Enforces symbolic boundary constraints across all traces
# Usage: ./scripts/check_trace_integrity.sh [--strict]

set -o errexit
set -o nounset
set -o pipefail


# Update these paths to match your actual directory structure
ARTIFACT_ROOT="philosophy/artifacts"
SYSTEM_ROOT="philosophy/entropy_index"
BREACH_LOG="philosophy/breach/breach_logs/$(date +%Y%m%d_%H%M%S)_structural_breach.md"
BLOCK_COMMIT=false  # Default: warn but allow commit
DIR_MISSING_OK=true # Allow missing directories

touch "$BREACH_LOG"


log_breach() {
  local severity="$1"
  local msg="$2"
  local hash="${3:-NO_HASH}"
  
  {
    echo "## $severity"
    echo "- Message: $msg"
    echo "- Hash: \`$hash\`"
    echo "- Timestamp: $(date -u)"
    echo "- Action: $([ "$severity" == "CRITICAL" ] && echo "BLOCKED" || echo "ALLOWED")"
  } >> "$BREACH_LOG"
}

check_directory() {
  local dir="$1"
  local domain="$2"
  
  if [[ ! -d "$dir" ]]; then
    log_breach "WARNING" "Missing $domain directory: $dir" "N/A"
    $DIR_MISSING_OK && return 0 || exit 1
  fi
  
  if [[ -z "$(ls -A "$dir")" ]]; then
    log_breach "INFO" "Empty $domain directory: $dir" "N/A"
    return 0
  fi
  return 0
}

validate_trace_dir() {
  local path="$1"
  local domain="$2"
  local base=$(basename "$path")
  local gen="${base%%_*}"
  local id="${base#*_}"
  local manifest="$path/input_manifest.txt"

  # Critical validations
  if [[ ! -f "$manifest" ]]; then
    log_breach "CRITICAL" "Missing manifest: $path" "N/A"
    BLOCK_COMMIT=true
    return
  fi

  # Field validation
  local fsm tension collapse
  fsm=$(grep -E 'FSM_WEIGHT' "$manifest" | awk '{print $2}' || true)
  tension=$(grep -E 'Tension' "$manifest" | sed 's/[^0-9.]//g' || true)
  collapse=$(grep -E 'Collapse_Log' "$manifest" | awk '{print $2}' || true)

  if [[ -z "$fsm" || -z "$tension" || -z "$collapse" ]]; then
    log_breach "CRITICAL" "Incomplete manifest: $path" "$(find "$path" -type f -exec sha256sum {} \; | sha256sum | awk '{print $1}')"
    BLOCK_COMMIT=true
    return
  fi

  # Domain boundary checks
  case $domain in
    "artifact")
      if [[ "$id" =~ ^(ideational|interpersonal|textual)$ ]]; then
        log_breach "CRITICAL" "FSM role in artifact domain: $id" "$(find "$path" -type f -exec sha256sum {} \; | sha256sum | awk '{print $1}')"
        BLOCK_COMMIT=true
      fi
      ;;
    "system")
      if [[ "$id" =~ ^tau_.* ]]; then
        log_breach "CRITICAL" "Artifact pattern in system domain: $id" "$(find "$path" -type f -exec sha256sum {} \; | sha256sum | awk '{print $1}')"
        BLOCK_COMMIT=true
      fi
      ;;
  esac

  # Generational lineage (warning only)
  if [[ "$gen" =~ gen([2-9][0-9]*) ]]; then
    local prev=$(( ${BASH_REMATCH[1]} - 1 ))
    local prev_dir=$(dirname "$path")/gen${prev}_${id}
    if [[ ! -d "$prev_dir" ]]; then
      log_breach "WARNING" "Missing parent generation: $prev_dir" "N/A"
    fi
  fi
}

main() {
  echo "🚦 Beginning structural trace integrity scan..."
  
  # Check directory existence and contents
  check_directory "$ARTIFACT_ROOT" "artifact"
  check_directory "$SYSTEM_ROOT" "system"

  # Validate traces if directories exist
  [[ -d "$ARTIFACT_ROOT" ]] && find "$ARTIFACT_ROOT" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    validate_trace_dir "$dir" "artifact"
  done

  [[ -d "$SYSTEM_ROOT" ]] && find "$SYSTEM_ROOT" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    validate_trace_dir "$dir" "system"
  done

  echo -e "\n📄 Breach log recorded at: $BREACH_LOG"
  
  # Final decision
  if $BLOCK_COMMIT; then
    echo "❌ Critical violations detected - commit blocked"
    exit 1  # CRITICAL: Block commit
  else
    echo "✅ No critical violations - commit allowed"
    exit 0  # ALLOWED: Proceed with commit
  fi
}

# Handle --strict flag
if [[ "$*" =~ "--strict" ]]; then
  DIR_MISSING_OK=false
fi

main