# STRUCTURE: Separation of Concerns Policy

## Purpose

This document defines structural boundaries between repository domains and establishes enforceable constraints for maintaining trace integrity.

The objective is to prevent:

* Cross-domain contamination
* Unauthorized mutation paths
* Ambiguous artifact lineage
* Integrity loss through bypassed validation

All constraints defined here are machine-checkable and enforced through validation scripts and breach logging.

---

## Domain Model

### Repository Namespaces

| Domain           | Path                                  | Mutability           | Authorized Tooling            | Validation Mechanism        |
| ---------------- | ------------------------------------- | -------------------- | ----------------------------- | --------------------------- |
| Raw Inputs       | `/artifacts/raw_inputs/`              | Uncontrolled         | None                          | Manual review               |
| Formal Artifacts | `/philosophy/entropy_index/artifact/` | Generation-immutable | `encode_artifact.sh`          | SHA-256 manifest validation |
| System Roles     | `/philosophy/entropy_index/system/`   | Versioned            | `generate_entropy_trace.sh`   | Entropy delta checks        |
| FSM Logic        | `/semiotic_engine/src/fsm/`           | Code-mutable         | Direct edits                  | `test_fsm_rigidity.sh`      |
| Quarantine       | `/philosophy/quarantine/`             | Temporary            | `scan_unencoded_artifacts.sh` | Timestamp + presence checks |
| Breach Logs      | `/philosophy/breach/breach_logs/`     | Append-only          | Automated logging             | Immutable hash verification |

Each domain has a defined mutation surface and validation boundary.

---

## Boundary Enforcement Rules

### 1. Cross-Domain Write Prohibition

No script or tool may write output into a domain it does not explicitly own.

Example (invalid):

```bash
generate_entropy_trace.sh textual gen1 2.3 --output ../entropy_index/artifact/
```

Enforcement:

* Execution halted
* Breach logged to `breach_logs/`
* Violation classified

---

### 2. Raw-to-Formal Bypass Prohibition

All raw inputs must pass through quarantine before formal encoding.

Valid flow:

```
raw_inputs/ → quarantine/ → encode_artifact.sh → entropy_index/artifact/
```

Direct writes to `entropy_index/artifact/` are prohibited.

---

### 3. Metric and Domain Isolation

Artifact metrics and system metrics must remain independent.

* FSM role identifiers may not appear in artifact IDs.
* Artifact tension values must not influence FSM weight calculations.
* System entropy values must not be injected into artifact manifests.

Metric independence is enforced during validation runs.

---

## Validation Workflow

### Namespace Validation

```bash
./scripts/validate_topography.sh --strict
```

Expected results:

* No foreign entities in artifact domain
* No rhetorical traces in system domain
* All quarantine entries timestamped

All violations are logged.

---

### Post-Mutation Verification

Upon mutation:

1. Boundary validation executes
2. Manifest hash is recalculated
3. Entropy delta is recorded
4. Breach logs are appended if violations occur

Mutation cannot proceed if blocking violations are detected.

---

## Violation Examples

### Category Error

Attempting to encode system code as an artifact:

```bash
./scripts/encode_artifact.sh semiotic_engine/src/fsm/ideational.py
```

Result:

* Execution halted
* Breach logged with classification

---

### Manual Directory Bypass

```bash
cp raw_idea.md philosophy/entropy_index/artifact/gen1_illegal/
```

Detection:

* Manifest mismatch during next validation run
* Breach entry created

---

## Design Rationale

### Separation of Domains

Artifacts, system roles, and FSM logic serve different purposes and follow different mutation rules. Separation ensures:

* Deterministic validation
* Clear lineage tracking
* Reduced cross-domain coupling
* Traceable failure modes

### Metric Independence

| Domain   | Primary Metric | Source                  |
| -------- | -------------- | ----------------------- |
| Artifact | Tension        | Manifest input          |
| System   | Entropy delta  | Hash comparison         |
| FSM      | Weight         | Source code declaration |

Metrics are evaluated independently and are not interchangeable.

---

## Related Documentation

* [Weight Verification](verification/weights.md)
* [Ethical Constraints](ETHICS.md#accountability-framework)
* [Mutation Tracking](USAGE.md#generation-workflows)

---

This policy defines enforceable structural constraints.
Violations result in logged breaches and may invalidate affected traces.

---
