#!/bin/bash
# check_trace_integrity.sh — Enforces symbolic boundary constraints across all traces
# Usage: ./scripts/check_trace_integrity.sh [--strict]

set -o errexit
set -o nounset
set -o pipefail

# Define root paths
ARTIFACT_ROOT="philosophy/artifacts"
SYSTEM_ROOT="philosophy/entropy_index"
BREACH_LOGS_DIR="philosophy/breach/breach_logs"
BLOCK_COMMIT=false
DIR_MISSING_OK=true

mkdir -p "$BREACH_LOGS_DIR"

# Function to log breaches with multi-dimensional classification
log_breach() {
  local severity="$1"
  local msg="$2"
  local hash="${3:-NO_HASH}"
  local category="${4:-structural}"

  local branch; branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-branch")
  local branch_safe="${branch//\//_}"
  local timestamp; timestamp=$(date +%Y%m%d_%H%M%S)
  local date_dir="$BREACH_LOGS_DIR/$(date +%Y/%m/%d)"
  local severity_dir="$BREACH_LOGS_DIR/by_severity/${severity,,}"
  local branch_dir="$BREACH_LOGS_DIR/by_branch/$branch_safe"
  local category_dir="$BREACH_LOGS_DIR/by_category/$category"

  mkdir -p "$date_dir" "$severity_dir" "$branch_dir" "$category_dir"

  local log_id="${timestamp}_${branch_safe}_${severity,,}_${category}"
  local log_path="$date_dir/$log_id.md"

  cat > "$log_path" <<EOF
## $severity
- Branch: $branch
- Category: $category
- Message: $msg
- Hash: \`$hash\`
- Timestamp: $(date -u)
- Action: $([ "$severity" == "CRITICAL" ] && echo "BLOCKED" || echo "ALLOWED")
- Log ID: $log_id
EOF

  ln -sf "../../../$log_path" "$severity_dir/${log_id}.md"
  ln -sf "../../../$log_path" "$branch_dir/${timestamp}_${severity,,}_${category}.md"
  ln -sf "../../../$log_path" "$category_dir/${timestamp}_${branch_safe}_${severity,,}.md"

  echo "Breach logged to: $log_path (classified)"
  
  if [[ "${severity,,}" == "critical" ]]; then
    local summary_file="$BREACH_LOGS_DIR/CRITICAL_SUMMARY.md"
    echo "- $(date -u): [$branch] $msg ($category)" >> "$summary_file"
  fi
}
# Checks if a directory exists and is not empty; logs breach if missing or empty.
check_directory() {
  local dir="$1"
  local domain="$2"

  if [[ ! -d "$dir" ]]; then
    log_breach "WARNING" "Missing $domain directory: $dir" "N/A" "directory"
    $DIR_MISSING_OK && return 0 || exit 1
  fi

  if [[ -z "$(ls -A "$dir")" ]]; then
    log_breach "INFO" "Empty $domain directory: $dir" "N/A" "directory"
    return 0
  fi
  return 0
}

# Validates the trace directory by checking for required manifest and proper field entries.
validate_trace_dir() {
  local path="$1"
  local domain="$2"
  local base; base=$(basename "$path")
  local gen="${base%%_*}"
  local id="${base#*_}"
  local manifest="$path/input_manifest.txt"

  if [[ ! -f "$manifest" ]]; then
    log_breach "CRITICAL" "Missing manifest: $path" "N/A" "manifest"
    BLOCK_COMMIT=true
    return
  fi

  # Field validation from manifest content
  local fsm tension collapse
  fsm=$(grep -E 'FSM_WEIGHT' "$manifest" | awk '{print $2}' || true)
  tension=$(grep -E 'Tension' "$manifest" | sed 's/[^0-9.]//g' || true)
  collapse=$(grep -E 'Collapse_Log' "$manifest" | awk '{print $2}' || true)

  if [[ -z "$fsm" || -z "$tension" || -z "$collapse" ]]; then
    local hash; hash=$(find "$path" -type f -exec sha256sum {} \; | sha256sum | awk '{print $1}')
    log_breach "CRITICAL" "Incomplete manifest fields in: $path" "$hash" "manifest"
    BLOCK_COMMIT=true
    return
  fi

  local hash; hash=$(find "$path" -type f -exec sha256sum {} \; | sha256sum | awk '{print $1}')

  # Domain-specific validations
  case $domain in
    "artifact")
      if [[ "$id" =~ ^(ideational|interpersonal|textual)$ ]]; then
        log_breach "CRITICAL" "FSM role detected in artifact domain: $id" "$hash" "domain"
        BLOCK_COMMIT=true
      fi
      ;;
    "system")
      if [[ "$id" =~ ^tau_.* ]]; then
        log_breach "CRITICAL" "Artifact detected in system domain: $id" "$hash" "domain"
        BLOCK_COMMIT=true
      fi
      ;;
  esac

  # Check for missing parent generation (warning only)
  if [[ "$gen" =~ gen([2-9][0-9]*) ]]; then
    local prev=$(( ${BASH_REMATCH[1]} - 1 ))
    local prev_dir=$(dirname "$path")/gen${prev}_${id}
    if [[ ! -d "$prev_dir" ]]; then
      log_breach "WARNING" "Missing parent generation: $prev_dir" "N/A" "lineage"
    fi
  fi
}

# Main execution flow for scanning directories and validating traces.
main() {
  echo "🚦 Starting structural trace integrity scan..."

  check_directory "$ARTIFACT_ROOT" "artifact"
  check_directory "$SYSTEM_ROOT" "system"

  [[ -d "$ARTIFACT_ROOT" ]] && find "$ARTIFACT_ROOT" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    validate_trace_dir "$dir" "artifact"
  done

  [[ -d "$SYSTEM_ROOT" ]] && find "$SYSTEM_ROOT" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    validate_trace_dir "$dir" "system"
  done

  echo -e "\n📄 Full breach log indexed in: $BREACH_LOGS_DIR"

  if $BLOCK_COMMIT; then
    echo "❌ CRITICAL violations present — commit blocked."
    exit 1
  else
    echo "✅ Structural check passed — no blocking violations."
    exit 0
  fi
}

[[ "$*" =~ --strict ]] && DIR_MISSING_OK=false
main
