## `CONTRIBUTING_Separation_of_Concerns.md`

### 🧭 Epistemic Function

This document formalizes the **ontological boundaries** and **mutation constraints** that govern the Symbolic Grammar Interpreter system.  
It is not a directory map — it is a **semiotic contract**.

No component is permitted to violate these boundaries **without triggering an epistemic breach condition**.

---

## 🔁 Functional Boundary Schema

| Layer         | Path                                        | Purpose                                           | Mutation Rule         | Access Control                           |
|---------------|---------------------------------------------|--------------------------------------------------|------------------------|-------------------------------------------|
| `raw_input`   | `artifacts/raw_inputs/`                    | Undifferentiated language matter                 | Mutable                | Manually managed                         |
| `literary`    | `philosophy/artifacts/literary_ideas/`     | Examined rhetorical content                      | Mutable (pre-trace)    | Intake-only via `scan_unencoded_artifacts.sh` |
| `quarantine`  | `philosophy/quarantine/holding_patterns/`  | Acknowledged ideas, pending encoding             | Mutable                | Manual review / encode-triggered         |
| `artifact`    | `philosophy/entropy_index/artifact/`       | Immutable generational traces of philosophical form | Append-only per gen    | `encode_artifact.sh` / `mutate_artifact.sh` |
| `system`      | `philosophy/entropy_index/system/`         | Generational traces of FSM roles                 | Recursive + Driftable  | `generate_entropy_trace.sh`              |
| `fsm_logic`   | `semiotic_engine/src/fsm/`                 | Executable agents for `system/` roles            | Editable with validation | Direct `.py` or CI-integrated scripts    |
| `docs`        | `philosophy/docs/`                         | Meta-discursive architecture & protocols         | Append-only (curated)  | `init_docs.sh` or manual commit          |
| `breach_logs` | `philosophy/breach/breach_logs/`           | Documentation of protocol violations             | Append-only            | Manual or automated breach triggers      |

---

## 🔒 Mutation Contracts

### 🔸 Artifacts

- Each artifact trace (`genN_<artifact>/`) is **epistemically frozen** at creation.
- Recursive mutation must occur via `mutate_artifact.sh`
- Mutations must:
  - Acknowledge origin generation
  - Increment generation counter
  - Log entropy delta and contradiction shift

### 🔸 System FSM Roles

- FSM-based traces may recurse via `generate_entropy_trace.sh --compare`
- Manifest fields are extracted from live FSM `.py` files and dialectical collapse logs
- Entropy delta and Hamming drift **must be** computed per generation

### 🔸 Boundary Violations

> Any trace created by a script **outside its valid domain** (e.g. using `generate_entropy_trace.sh` to encode a τ-operator) constitutes a **semiotic category breach**.

This must be logged in:

```bash
philosophy/breach/breach_logs/structural_violation_<timestamp>.md
```

The entry must include:

- Name of script
- Attempted target
- Detected domain mismatch
- Hash of invalid trace, if written

---

## 🧠 Ontological Principle

The distinction between **computational recursion** (e.g. FSMs) and **semantic recursion** (e.g. philosophical claims) is not aesthetic — it is **structural**.

Violation of this boundary results in **symbolic contamination**: where procedural data is mistaken for rhetorical position, or vice versa.

---

## 🚨 Forbidden Transformations

### ❌ Incorrect FSM trace using a rhetorical artifact

```bash
./scripts/generate_entropy_trace.sh tau_dual gen1 1.4
# ⛔ Invalid: `tau_dual` is a rhetorical construct, not an FSM role
```

### ❌ Artifact mutation by system-level comparison

```bash
# Invalid: artifacts must use mutate_artifact.sh
./scripts/generate_entropy_trace.sh τ_falsify gen2 2.1 --compare gen1
```

---

## ✅ Valid Trace Pipelines

### 📜 Philosophical Artifact

```bash
./scripts/encode_artifact.sh philosophy/artifacts/literary_ideas/tau_progress.md
```

Yields:

```
philosophy/entropy_index/artifact/gen1_tau_progress/
├── input_manifest.txt
├── entropy_value.txt
├── interpretation.md
└── raw_artifact.md
```

### ⚙️ FSM Role

```bash
./scripts/generate_entropy_trace.sh ideational gen3 2.5 --compare gen2
```

Yields:

```
philosophy/entropy_index/system/gen3_ideational/
├── input_manifest.txt
├── entropy_value.txt
├── delta_entropy.txt
├── interpretation.md
└── entropy_diff_manifest.md
```

---

## 🧩 Enforcement Summary

| Rule | Description | Enforced By |
|------|-------------|-------------|
| Gen1 Immutability | `gen1_` directories must never be overwritten | `encode_artifact.sh`, `generate_entropy_trace.sh` |
| Path Sanity | FSM traces only under `system/`; Artifacts only under `artifact/` | Explicit path guards |
| Quarantine Intake | All ideas must pass through `quarantine/` before encoding | `scan_unencoded_artifacts.sh` |
| Breach Traceability | All violations must be documented in `breach_logs/` | Manual or CI-integrated |

---

## 📚 Cross-links

- [USAGE.md](USAGE.md)
- [STRUCTURE.md](STRUCTURE.md)
- [FAQ.md](FAQ.md)
- [ETHICS.md](ETHICS.md)

---

## 🧬 Final Note

This document is not a policy — it is a **systemic axiom**. If your toolchain violates these distinctions, the output is not just invalid — it is **epistemically incoherent**.

This file must be version-controlled. Changes require a justification encoded in `ETHICS.md`.

---
