# CONTRIBUTING.md — Epistemic Integrity Protocol

```mermaid
flowchart TD
    A[Contribution] --> B{{"Artifact or System?"}}
    B -->|Artifact| C[Quarantine Scan]
    B -->|System| D[Paradox Check]
    C --> E[Encode & Validate]
    D --> F[Trace & Compare]
    E --> G[Epistemic Atlas]
    F --> G
```

---

## 🛡️ Contribution Principles

### 1. **Ontological Purity**
- **Artifacts** (literary ideas) and **System** (FSM roles) *must never intersect*  
- Use [scan_unencoded_artifacts.sh](USAGE.md#scan) before submitting raw ideas  
- System contributions require [paradox detection logs](content/specs/dialectical_cores/)  

### 2. **Gen1 Immutability**
```mermaid
classDiagram
    class ArtifactTrace {
        +gen1_* directories
        -input_manifest.txt
        -entropy_value.txt
        +immutable: true
    }
    ArtifactTrace <|-- MutatedTrace : inherits
    class MutatedTrace {
        +gen2_* directories
        +delta_entropy.txt
    }
```
- Never modify files under `entropy_index/artifact/gen1_*/`  
- Mutate via [mutate_artifact.sh](USAGE.md#mutation) to create new generations  

### 3. **Epistemic Firewall**
- New ideas must pass through `quarantine/holding_patterns/` ([rationale](FAQ.md#quarantine))  
- Reserved FSM role names (`ideational`, etc.) are **off-limits** for artifacts  

---

## 🧩 Contribution Workflow

### For Artifacts
```mermaid
sequenceDiagram
    Contributor->>+LiteraryDir: Add idea.md
    LiteraryDir->>+Scanner: scan_unencoded_artifacts.sh
    Scanner->>+Quarantine: Move to holding_patterns/
    Contributor->>+Encoder: encode_artifact.sh
    Encoder->>-EntropyIndex: Create gen1_* trace
```

### For System Code
```mermaid
gantt
    title System Contribution Timeline
    dateFormat  YYYY-MM-DD
    section Mandatory
    Run Paradox Detector :a1, 2023-01-01, 1d
    Generate Logs :a2, after a1, 1d
    Create Trace :a3, after a2, 1d
    section Validation
    Ontology Check :after a3, 1d
    Cross-Domain Audit :after a3, 2d
```

---

## 🚨 Validation Protocol

### Pre-Submit Checks
```bash
# Validate artifact contributions
../../scripts/validate_ontology.sh --domain=artifact

# Audit system contributions
../../scripts/validate_ontology.sh --domain=system --strict
```

### Output Interpretation
| Result              | Action                               |
|---------------------|--------------------------------------|
| `✅ Ontology intact` | Ready for PR                         |
| `❌ Boundary breach` | Fix using [FAQ#firewall](FAQ.md#firewall-analogy) |
| `⚠️ Tension mismatch` | Recalibrate δ via [USAGE.md#tension](USAGE.md#artifact-encoding) |

---

## 📜 Documentation Standards

### Cross-Reference Rules
```mermaid
flowchart LR
    A[Contribution] --> B[[STRUCTURE.md]]
    A --> C[[USAGE.md]]
    A --> D[[FAQ.md]]
    B -->|Section| E[#immutability-rules]
    C -->|Anchor| F[#system-drift]
    D -->|Link| G[#metric-parallelism]
```
- All PRs must reference relevant documentation anchors  
- New features require [knowledge graph](OVERVIEW.md) updates  

---
### FSM Modification Protocol
1. Update FSM code  
2. Run rigidity test:  
```bash
../../scripts/test_fsm_rigidity.sh <role> <new_gen> <tension>
```
- CMS must align with FSM_WEIGHT (±20% tolerance)

- Submit trace + validation report




---
## ⚖️ Ethical Constraints

### Prohibited Actions
- Modifying SHA-256 hashes in `entropy_value.txt` post-encoding  
- Using system roles (`ideational`, etc.) as artifact names  
- Bypassing quarantine via direct writes to `entropy_index/`  

### Compliance
- Review [Ethics Charter](ETHICS.md)  
- Pass automated [integrity checks](scripts/validate_ethics.sh)  

---

```bash
# Run full validation suite
../../scripts/validate_contribution.sh --strict
```

[Begin Contribution](USAGE.md#quickstart){ .md-button }  
[Report Epistemic Breach](content/specs/ETHICS.md#reporting){ .md-button }  
