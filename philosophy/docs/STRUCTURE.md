# STRUCTURE.md — Ontological Hierarchy & Boundary Semantics

## 🗂️ Filesystem Topography
```mermaid
flowchart TD
    Root[philosophy/]
    Root --> A[artifacts/literary_ideas/]
    Root --> B[quarantine/holding_patterns/]
    Root --> C[entropy_index/]
    Root --> D[dialectical_cores/]
    Root --> E[semiotic_engine/src/fsm/]
    
    C --> C1[artifact/gen1_<name>/]
    C --> C2[system/genX_<role>/]
    
    style A stroke:#4CAF50,stroke-width:2px
    style B stroke:#FF9800,stroke-width:2px
    style C1 stroke:#2196F3,stroke-width:2px
    style C2 stroke:#9C27B0,stroke-width:2px
```

### Domain-Specific Directories
| Directory | Type | Mutable? | Script Dependency |
|-----------|------|----------|--------------------|
| `literary_ideas/` | Ephemeral Input | Yes | `scan_unencoded_artifacts.sh` |
| `holding_patterns/` | Quarantine Buffer | Yes | `encode_artifact.sh` |
| `artifact/gen1_*/` | Immutable Trace | ❌ No | `mutate_artifact.sh` (future gens) |
| `system/genX_*/` | Versioned Trace | Yes (via new gens) | `generate_entropy_trace.sh --compare` |

---

## 🔒 Immutability Rules
```mermaid
gantt
    title Trace Lifecycle Rules
    dateFormat  YY-MM-DD
    axisFormat %m/%d
    
    section Artifact
    Gen1 Creation :a1, 23-01-01, 1d
    Gen1 Lock :after a1, 23-01-02, 365d
    
    section System
    GenN Creation :b1, 23-01-01, 1d
    GenN+1 Comparison :b2, after b1, 2d
```

### Artifact Traces (`entropy_index/artifact/`)
- **Immutable After Creation**:  
  ```bash
  # encode_artifact.sh line 21-24
  if [[ -d "$OUTPUT_DIR" ]]; then
    echo "❌ ERROR: $OUTPUT_DIR exists. Gen1 is immutable." >&2
    exit 1
  fi
  ```
- **Allowed Operations**:  
  - Read (`interpretation.md`)  
  - Compare (via external tools)  
  - Mutate **only** through new generations  

### System Traces (`entropy_index/system/`)
- **Generational Evolution**:  
  ```python
  # generate_entropy_trace.sh comparison logic
  def hamming_distance(current, previous):
      return bin(current ^ previous).count('1')
  ```
- **Allowed Operations**:  
  - Overwrite prior gens (except those referenced by `--compare`)  
  - Delete unused gens  

---

## 🧩 Cross-Domain Interactions
```mermaid
flowchart LR
    Artifact[Artifact Pipeline] -->|"δTension input"| System[System Pipeline]
    System -->|"Collapse_Log data"| Artifact
    Quarantine -->|"Feeds raw ideas"| Artifact
    FSM[FSM Code] -->|"Defines role weights"| System
    
    style Artifact stroke:#2196F3,stroke-width:2px
    style System stroke:#9C27B0,stroke-width:2px
```

### Ontological Boundaries
| Aspect | Artifact Domain | System Domain |
|--------|-----------------|---------------|
| **Data Source** | User-authored `.md` files | FSM `.py` code |
| **Entropy Driver** | Interpretive contradictions | Code/log changes |
| **Mutation Tool** | `mutate_artifact.sh` (future) | `--compare` flag |
| **Output Example** | `gen1_tau_falsify/` | `gen5_ideational/` |

---
## New Entropy Index Artifacts

```bash
entropy_index/system/genX_<role>/
├── out1.txt                # Contradiction injection logs
├── cms_score.txt           # Collapse Metabolism Score
└── weight_validation.md    # FSM_WEIGHT alignment report
```
## 🚧 Common Structural Errors
### Artifact Domain
```text
ERROR: Cannot encode 'ideational' — reserved for system roles
```
**Fix**: Rename artifact to avoid FSM role names (see `semiotic_engine/src/fsm/`)

### System Domain
```text
ERROR: Missing gen3_paradox_log.md in dialectical_cores/
```
**Fix**: Generate collapse logs before tracing via `semiotic_engine/run_paradox_detector.sh`

### Cross-Domain
```text
WARNING: Tension mismatch between artifact (δ3.2) and system (δ4.1)
```
**Resolution**: See `philosophy/guidelines/tension_calibration.md`

---

## ▶️ Navigational Map
```mermaid
flowchart LR
    Structure[STRUCTURE.md] --> Usage[USAGE.md]
    Usage --> Overview[OVERVIEW.md]
    Overview --> Glossary[GLOSSARY.md]
    Glossary --> FAQ[FAQ.md]
    
    click Overview "OVERVIEW.md" "System visualization"
    click Glossary "GLOSSARY.md" "Term definitions"
```

**Next**: Consult [FAQ.md](FAQ.md) for methodological justifications of this structure.