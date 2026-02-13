# Epistemic Trace Engine Roadmap

This roadmap is an engineering plan for strengthening determinism, auditability, and constraint enforcement.

It is **not** a roadmap to a “truth engine.”
Any component that touches natural language is treated as a **weak-signal heuristic** unless it is scored against outcomes.

The guiding principle is: procedural guarantees first, epistemic claims only where empirically grounded.

---

## 0. Definitions and Non-Goals

### Definitions
- **Snapshot**: a declared set of files + content hashes + tool version + timestamp.
- **Run**: a single execution over one Snapshot producing metrics and reports.
- **Invariant**: an explicitly declared constraint with a deterministic evaluation function.
- **Drift**: descriptive characterization of change (never conflated with integrity).
- **Breach**: a typed violation of declared policy or invariant thresholds.

### Non-Goals
- No automatic semantic truth evaluation.
- No logical entailment guarantees.
- No “Bayesian updating” unless likelihood-ratio inputs exist.
- No always-on monitoring daemon as a core dependency.

---

## 1. Current Structural Risks (What Can Go Wrong Now)

This section enumerates failure modes that reduce auditability or encourage epistemic overclaiming.

### 1.1 Manifest Format Ambiguity
**Risk:** The system mixes “YAML tags” with non-YAML manifest inputs or ad hoc parsing.  
**Failure mode:** silent parse inconsistencies; different runs interpret the same manifest differently.

**Fix:** choose one:
- Standardize manifests as YAML (versioned schema), or
- Keep text manifests and implement a strict canonical parser + canonicalization.

### 1.2 Schema Ownership Split
**Risk:** the same schema type (e.g., `Manifest`) is defined in multiple packages.  
**Failure mode:** drift between definitions; broken backward compatibility without detection.

**Fix:** single source of truth:
- `pkg/manifest` owns schema, versioning, and canonicalization.
- Other packages import and embed.

### 1.3 Scattered Domain Rules
**Risk:** directory layout rules, valid role names, allowed artifact IDs, etc. are enforced via scattered regex checks.  
**Failure mode:** “policy patchwork,” inconsistent enforcement, brittle refactors.

**Fix:** central policy registry:
- `internal/policy` (or `pkg/policy`) owns directory contract, allowed names, reserved prefixes, run directory layout.

### 1.4 Integrity/Drift Conflation
**Risk:** integrity hashes are used or named in a way that tempts drift inference.  
**Failure mode:** hash comparisons get treated as semantic change measures.

**Fix:** strict separation:
- `integrity/`: canonicalization + hashing + tamper checks only.
- `drift/`: surface metrics only.
Prohibit drift modules from consuming hash-diff metrics.

### 1.5 “Rigorous Word” Overclaim
**Risk:** modules named `bayesian`, `logical_form`, `contradiction_detection` imply epistemic validity.  
**Failure mode:** users (including future you) treat heuristics as truth-like.

**Fix:** rename to accuracy:
- `confidence_ledger` (unless LR-based Bayes)
- `pattern_forms` (not logical form)
- `conflict_signals` (not contradiction detection)
- `claim_candidates` (not claim identification)

### 1.6 Continuous Monitoring Trap
**Risk:** vault watch mode creates ambiguous provenance and operational complexity.  
**Failure mode:** unclear state at time of report; debounce/cache bugs; repeated false positives.

**Fix:** snapshot-trigger model only:
- `snapshot` command creates snapshot ID.
- `audit --snapshot <id>` produces a run directory keyed by snapshot hash.
Optional triggers live outside the core.

### 1.7 Quadratic Conflict Scan
**Risk:** naive pairwise scan across all candidates is O(n²).  
**Failure mode:** performance collapse on nontrivial vaults; users stop trusting output.

**Fix:** candidate indexing:
- token-based inverted index (no ML dependency)
- optional minhash/LSH bucketing for shingles
- blocking keys to reduce comparison set

---

## 2. Roadmap Phases (Ordered by Leverage)

### Phase 1 — Deterministic Core (Go CLI Migration)
**Goal:** replace shell orchestration with typed, testable, deterministic Go code.

Deliverables:
- `trace snapshot` produces `snapshot.json` with canonical ordering.
- `trace audit --snapshot <hash>` produces one run directory with deterministic outputs.
- `integrity` package with canonicalization rules and versioned hash scheme.
- `policy` registry module centralizing directory contracts and naming constraints.
- End-to-end golden tests: same snapshot must reproduce identical outputs.

Exit criteria:
- Reproducible runs on two machines produce identical run artifacts (except timestamp fields, which must be explicitly excluded or normalized).
- No duplicated schema definitions.
- No scattered policy regex checks.

---

### Phase 2 — Constraint Enforcement and Breach Typing
**Goal:** ensure all invariants and thresholds are explicit, versioned, and enforced.

Deliverables:
- Typed breach taxonomy (e.g., `SCHEMA_VIOLATION`, `INVARIANT_FAIL`, `SNAPSHOT_MISMATCH`, `UNAUTHORIZED_PATH`).
- `policy.yaml` or `policy.json` defining thresholds and enabled checks (versioned).
- CLI exits nonzero on breach in strict mode; permissive mode writes breaches but continues.

Exit criteria:
- Threshold changes require explicit policy version bump.
- Breach logs are immutable run artifacts.
- No invariant check runs without producing a recorded result.

---

### Phase 3 — Drift Metrics (Explicitly Surface-Level)
**Goal:** provide descriptive drift metrics without implying semantic correctness.

Deliverables:
- `drift/surface` metrics: edit distance, token diff counts, Jaccard over normalized tokens, section churn.
- Metric definitions file: exact tokenization/canonicalization details.
- Run reports clearly label drift as surface/descriptive only.

Exit criteria:
- Drift outputs are stable under canonicalization changes only when versioned.
- Drift metrics never depend on integrity hash comparisons.

---

### Phase 4 — Heuristic Signal Layer (Candidate Claims + Conflict Signals)
**Goal:** surface weak signals for review without overclaiming.

Deliverables:
- `claims/candidates`: pattern-based extraction of declarative candidates.
- `conflicts/signals`: pattern-based tension flags (negation flips, antonym lists, modal conflicts), clearly labeled heuristic.
- Indexing to avoid O(n²) scans.

Exit criteria:
- Output includes an explicit “error expected” disclaimer and versioned rule set.
- Precision/recall is measured on a small curated set (even if local and minimal).
- Conflict scans scale subquadratically via indexing.

---

### Phase 5 — Optional Prediction & Scoring (Only Source of Epistemic Legitimacy)
**Goal:** enable epistemic claims only where tied to outcomes.

Deliverables:
- `claims/predictions`: optional prediction format linked to claims.
- Outcome recording format.
- Scoring metrics (Brier/log score) and calibration report command.

Exit criteria:
- Scores computed only when outcomes exist.
- Reports distinguish “heuristic signals” from “scored predictions.”
- No probabilistic language in reports unless scoring is enabled.

---

## 3. Immediate Next Fixes (Highest Priority)

1. Decide and enforce manifest format (YAML vs strict text parser + canonicalization).
2. Establish single schema ownership (`pkg/manifest`).
3. Create `policy` registry for all domain rules.
4. Implement snapshot-trigger run model and remove watch mode from core.
5. Enforce integrity/drift separation at package boundaries.
6. Rename heuristic modules to remove implied epistemic authority.

---

## 4. Testing and Reproducibility Requirements

### Golden tests
- Same snapshot on same version → identical outputs.
- Canonical ordering enforced for file lists and JSON keys where relevant.
- All metric definitions versioned and included in run artifacts.

### Mutation audit invariants
- No run output may overwrite prior runs.
- Any policy change must be recorded with version bump.
- Any breach must produce a typed breach record.

---

## 5. Success Criteria (What “Done” Means)

This project is “structurally sound” when:

- Snapshots and runs are reproducible and auditable.
- Invariants and thresholds are explicit and versioned.
- Drift metrics are clearly descriptive and cannot be misread as integrity or truth.
- Heuristic signals are labeled as weak and have measured error rates.
- Optional scoring exists for any claim of epistemic validity.

Analytically: the engine provides procedural constraint (determinism, immutability, explicit policy, typed breaches) and restricts epistemic language to modules that are empirically grounded via prediction scoring rather than semantic assertion.
