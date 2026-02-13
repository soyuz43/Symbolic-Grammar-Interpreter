# OVERVIEW.md — System Knowledge Graph & Epistemic Topography

```mermaid
flowchart TD
    A[["OVERVIEW.md (Central Hub)"]]
    A --> B[[FAQ.md]]
    A --> C[[USAGE.md]]
    A --> D[[STRUCTURE.md]]
    A --> E[[GLOSSARY.md]]
    B -->|"#script-changes"| C
    C -->|"#artifact-encoding"| D
    D -->|"#immutability-rules"| B
    E -->|"τ operator"| C
    click B "FAQ.md" "Methodological Q&A"
    click C "USAGE.md" "Operational workflows"
    click D "STRUCTURE.md" "Ontological layout"
    style A stroke-width:4px,stroke:#2196F3
```

---

## 🌐 Knowledge Graph Topography

### Cross-Document Query System
```mermaid
flowchart LR
    Q{{"User Question"}}
    Q -->|"What's Gen1?"| FAQ["FAQ.md#gen1-immutability"]
    Q -->|"How to compare traces?"| USAGE["USAGE.md#system-drift"]
    Q -->|"Directory rules?"| STRUCTURE["STRUCTURE.md#boundary-enforcement"]
    
    FAQ --> CODE["encode_artifact.sh (Lines 21-24)"]
    USAGE --> EXAMPLE["/examples/trace_comparison/"]
    STRUCTURE --> VALIDATOR["../../scripts/validate_ontology.sh"]
    
    style Q stroke:#FF9800,stroke-width:3px
    linkStyle 0 stroke:#4CAF50,stroke-width:2px
    linkStyle 1 stroke:#9C27B0,stroke-width:2px
```

---

## 🧩 Epistemic Boundaries

### Artifact vs System Domains
```mermaid
mindmap
    root((Epistemic Boundaries))
        Artifact
            Human-Authored
            Immutable Gen1
            Subjective Tension (δ)
            Falsification Baseline
        System
            Code-Derived
            Versioned Gens
            Hamming Distance
            Paradox Logs
        Firewall
            scan_unencoded_artifacts.sh
            Reserved Name Checks
            Quarantine Buffer
```

---

## 🔄 Mutation Drivers

### Trace Lifecycle
```mermaid
gantt
    title Mutation Timeline
    dateFormat  YYYY-MM-DD
    axisFormat %m/%d
    
    section Artifact
    Gen1 Creation :a1, 2023-01-01, 1d
    Mutate to Gen2 :a2, after a1, 3d
    
    section System
    GenN Commit :b1, 2023-01-05, 1d
    Compare GenN+1 :b2, after b1, 2d
    Drift Analysis :b3, after b2, 2d
    
    section Constraints
    Gen1 Immutable :crit, 2023-01-01, 364d
```

---

## 🔗 Cross-Document Anchors

### Deep Link Network
```mermaid
flowchart TD
    A[FAQ.md#gen1] --> B[[STRUCTURE.md#immutability]]
    A --> C[[USAGE.md#artifact-encoding]]
    C --> D[[scripts/encode_artifact.sh]]
    B --> E[[specs/entropy_index/artifact/]]
    
    style A stroke:#FF9800
    style B stroke:#4CAF50
    linkStyle 0 stroke:#FF9800,stroke-width:2px
    linkStyle 1 stroke:#9C27B0,stroke-width:2px
```

---

## 🕸️ Visual Query System

### "How do I...?" Pathways
```mermaid
sequenceDiagram
    User->>CLI: ../../scripts/render_epistemic_map.sh
    CLI->>Documentation: Query anchors
    Documentation->>Mermaid: Generate graph
    Mermaid->>User: Interactive diagram
    User->>FAQ.md: Click node
    FAQ.md->>STRUCTURE.md: Deep link
```

---

## 🚨 Troubleshooting Pathway

```mermaid
flowchart TD
    Error["❌ ERROR: Reserved FSM name"] --> Fix1["Check FAQ.md#name-conflict"]
    Fix1 --> Fix2["Rename artifact per STRUCTURE.md#naming-rules"]
    Fix2 --> Verify[Run validate_ontology.sh]
    Verify -->|Success| Log["Log updated in dialectical_cores/"]
    Verify -->|Failure| Issue["Open GitHub issue #epistemic-integrity"]
    
    style Error stroke:#f00,stroke-width:2px
    style Fix2 stroke:#4CAF50
```

---

## 📊 Metric Parallelism

| Dimension       | Artifact Domain              | System Domain                |
|-----------------|------------------------------|------------------------------|
| **Entropy**     | SHA-256 of user metrics      | SHA-256 of code/log state     |
| **Mutation**    | Manual (mutate_artifact.sh)  | Auto-detected (--compare)     |
| **Visualization**| Conceptual tree diff        | Hamming distance heatmap     |
| **Immutable**   | Gen1                        | No — gens evolve             |

---

## ▶️ Navigational Commands
```bash
# Launch interactive knowledge graph
../../scripts/launch_knowledge_graph.sh --layers=3

# Example output
🌐 Epistemic Graph Loaded:
- FAQ.md#gen1 ↔ STRUCTURE.md#immutability
- USAGE.md#system-drift ↔ scripts/generate_entropy_trace.sh
```

[Begin Exploration](FAQ.md#navigation-guide){ .md-button } 
[Validate Structure](STRUCTURE.md#boundary-enforcement){ .md-button }
