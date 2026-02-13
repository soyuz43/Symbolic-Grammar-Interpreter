Below is a stripped-down, governance-legible rewrite.
No emojis.
Less philosophy.
Clearer compliance / audit framing.
Retains documentation links and structure.

---

# README.md

*Epistemic Trace Infrastructure*

[![Documentation Status](https://img.shields.io/badge/docs-validation-4CAF50)](docs/FALSIFICATION.md)
[![Contradiction Protocol](https://img.shields.io/badge/contradiction_flow-archived-9C27B0)](docs/CONTRADICTION_FLOW.md)

A deterministic snapshot–invariant–drift system for controlled artifact mutation and traceable state transitions.

---

## Overview

This repository implements a structured change-control framework that:

* Captures immutable snapshots of artifacts and system roles
* Applies defined constraint checks before mutation
* Ingests structured contradiction/pressure inputs
* Computes entropy-based drift metrics
* Logs lineage and breach events

The goal is reproducible, auditable evolution of structured artifacts.

---

## Core Invariants

### Artifact Controls

| Control            | Mechanism             | Validation Script          |
| ------------------ | --------------------- | -------------------------- |
| Tension thresholds | δTension vs CMS       | `validate_tension_cms.sh`  |
| Manifest integrity | Hash + boundary rules | `check_trace_integrity.sh` |

### System Controls

| Control              | Mechanism                | Validation Script         |
| -------------------- | ------------------------ | ------------------------- |
| Entropy drift bounds | ΔEntropy vs Weight       | `audit_weight_entropy.sh` |
| Role isolation       | FSM boundary enforcement | `test_fsm_rigidity.sh`    |

---

## Control Features

* Structured contradiction intake (YAML-based)
* Immutable generation directories
* Deterministic entropy hashing
* Boundary enforcement between raw, staged, and validated domains
* Typed breach logging

No artifact mutation bypasses validation.

---

## Mutation Pipeline

### Artifact Workflow

```
raw_inputs/ → quarantine/ → entropy_index/artifact/ → genN_trace/
```

### System Workflow

```
semiotic_engine/ → entropy_index/system/
```

Contradiction inputs are processed from:

```
contradictions/library/
```

---

## Key Scripts

| Script                      | Function                                     |
| --------------------------- | -------------------------------------------- |
| `encode_artifact.sh`        | Encode artifact into trace domain            |
| `mutate_artifact.sh`        | Controlled mutation with pressure validation |
| `generate_entropy_trace.sh` | Produce system-level trace                   |
| `check_trace_integrity.sh`  | Structural validation                        |
| `precommit_scan.sh`         | Pre-commit integrity enforcement             |

---

## Getting Started

### Encode an Artifact

```bash
../../scripts/encode_artifact.sh <artifact_name>
```

### Mutate Under Constraint

```bash
../../scripts/falsification/mutate_artifact.sh <artifact> <prev_gen> <new_gen> --pressure <yaml>
```

### Validate Integrity

```bash
../../scripts/validate_topography.sh --strict
```

See:

* [Falsification Protocol](docs/FALSIFICATION.md)
* [Contradiction Workflow](docs/CONTRADICTION_FLOW.md)
* [Usage Guide](docs/USAGE.md)

---

## Contribution Controls

Before committing:

1. All contradiction inputs must be structured and present
2. Tension and entropy thresholds must pass validation
3. No unresolved breach logs

Run:

```bash
../../scripts/precommit_scan.sh --full
../../scripts/audit_trace_lineage.sh --gen=all
```

See:

* [Contribution Guide](docs/CONTRIBUTING.md)
* [Ethical Constraints](docs/ETHICS.md)

---

## Scope

This system enforces:

* Deterministic snapshot capture
* Explicit invariant checks
* Controlled mutation
* Immutable trace lineage

It does not perform semantic truth evaluation or replace formal verification.

---

Analytically: this revision removes metaphorical and philosophical framing, replaces recursive/epistemic language with compliance-oriented terminology, and positions the project as a deterministic change-control and audit framework.
