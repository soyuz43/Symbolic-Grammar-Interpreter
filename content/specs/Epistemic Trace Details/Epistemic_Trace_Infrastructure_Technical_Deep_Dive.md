# Epistemic Trace Infrastructure Overview

This document provides a comprehensive visual and structural breakdown of the system's architecture, workflows, and methodological separation. Six Mermaid diagrams elucidate key interactions, flows, and boundaries.

---

## 📂 Directory Structure Topography

```mermaid
flowchart TD
    philosophy["philosophy/"]
    artifacts["artifacts/"]
    literary_ideas["literary_ideas/"]
    quarantine["quarantine/"]
    holding_patterns["holding_patterns/"]
    entropy_index["entropy_index/"]
    artifact_dir["artifact/"]
    system_dir["system/"]
    dialectical_cores["dialectical_cores/"]
    semiotic_engine["semiotic_engine/src/fsm/"]

    philosophy --> artifacts
    artifacts --> literary_ideas
    philosophy --> quarantine
    quarantine --> holding_patterns
    philosophy --> entropy_index
    entropy_index --> artifact_dir
    entropy_index --> system_dir
    philosophy --> dialectical_cores
    philosophy --> semiotic_engine
```

*Explanation:*  
- **literary_ideas/**: Raw, unencoded textual concepts
- **holding_patterns/**: Quarantined artifacts awaiting formalization
- **artifact/ & system/**: Encoded traces split by intentional vs emergent origins
- **dialectical_cores/**: Collapse logs from FSM role mutations

---

## 🤖 Script Responsibilities & Data Flow

```mermaid
flowchart LR
    encode[encode_artifact.sh\n📜 Symbolic Formalizer]
    generate[generate_entropy_trace.sh\n⚙️ System Drift Tracker]
    scan[scan_unencoded_artifacts.sh\n🧼 Epistemic Intake Manager]

    literary[literary_ideas/] --> scan
    scan --> holding[holding_patterns/]
    holding --> encode
    encode --> artifact_dir[entropy_index/artifact/]
    semiotic[semiotic_engine/src/fsm/] --> generate
    dialectical[dialectical_cores/] --> generate
    generate --> system_dir[entropy_index/system/]
```

*Key Interactions:*  
1. **scan** monitors literary_ideas/ → acts as intake filter
2. **encode** processes quarantined files → writes immutable Gen1 traces
3. **generate** ingests live FSM code → computes operational entropy

---

## 🧬 Artifact Encoding Sequence

```mermaid
sequenceDiagram
    participant User
    participant literary_ideas
    participant holding_patterns
    participant encode_script
    participant entropy_artifact

    User->>literary_ideas: Writes tau_falsify.md
    User->>scan_script: Runs scan_unencoded_artifacts.sh
    scan_script->>literary_ideas: Checks for unencoded files
    scan_script->>holding_patterns: Moves tau_falsify.md
    User->>encode_script: Runs encode_artifact.sh
    encode_script->>holding_patterns: Reads tau_falsify.md
    encode_script->>entropy_artifact: Generates gen1_tau_falsify/
```

*Process Guarantees:*  
- No direct writes from literary_ideas/ to entropy_index/  
- Explicit user intent required via encode_artifact.sh  
- Gen1 traces remain immutable against overwrites  

---

## 🚧 Methodological Separation of Pipelines

```mermaid
flowchart LR
    subgraph ArtifactPipeline[Artifact Pipeline]
        direction TB
        A[User Input] --> B[encode_artifact.sh]
        B --> C[entropy_index/artifact/]
        C --> D[Mutation via mutate_artifact.sh]
    end

    subgraph SystemPipeline[System Pipeline]
        direction TB
        E[FSM Code] --> F[generate_entropy_trace.sh]
        F --> G[entropy_index/system/]
        G --> H[Drift Detection via --compare]
    end

    scan[scan_unencoded_artifacts.sh] --> ArtifactPipeline
    SystemPipeline --> H
```

*Critical Boundaries:*  
- **Artifact**: User-driven, intentional claims  
- **System**: Code-derived, emergent behavior  
- **scan** enforces unidirectional flow into ArtifactPipeline  

---

## 🔥 Epistemic Firewall Mechanism

```mermaid
flowchart LR
    literary[literary_ideas/] --> scan[scan_unencoded_artifacts.sh]
    scan -->|Moves unencoded| holding[holding_patterns/]
    holding -->|Requires review| encode[encode_artifact.sh]
    encode -->|Writes to| entropy[entropy_index/artifact/]
    entropy -.->|Immutable Gen1| literary
    style scan stroke:#ff0000,stroke-width:2px
```

*Firewall Properties:*  
- Prevents accidental contamination of raw ideas into formal traces  
- **Red boundary**: scan acts as controlled gatekeeper  
- Mandates quarantine period for epistemic hygiene  

---

## 🧩 Mutation Driver Comparison

```mermaid
mindmap
    root((Mutation Drivers))
        Artifact
            User-assigned structure
            Interpretive contradiction
            User as drift vector
            Conceptual deformation
        System
            Code/logs extraction
            Functional logic changes
            System drift vector
            Operational divergence
```

*Contrasting Semantics:*  
- **Artifact** mutations reflect theoretical evolution  
- **System** mutations track computational role drift  
- Dual tracing enables comparative epistemology  

---
## Collapse Metabolism Algorithm  
```python
def compute_cms(recombinations: int, collapses: int) -> float:
    total = recombinations + collapses
    return (recombinations - collapses) / total if total > 0 else 0.0
```
## Weight Alignment Logic
```mermaid
flowchart TD
    A[Declared FSM_WEIGHT] --> B{{CMS > 50?}}
    B -->|Yes| C{{FSM_WEIGHT < 0.6?}}
    B -->|No| D{{CMS < 30?}}
    C -->|Yes| E[✅ Valid]
    C -->|No| F[❌ Invalid]
    D -->|Yes| G{{FSM_WEIGHT > 0.4?}}
    G -->|Yes| E
    G -->|No| F
```



---

To visualize rhetorical vs operational evolution:  
`bash scripts/render_topography.sh --mode comparative`