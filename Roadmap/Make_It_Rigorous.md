Mostly coherent as a *software refactor plan* (bash → Go CLI, modular packages, tests, Obsidian IO). Not coherent yet as a *rigorous epistemic instrument plan*, because Phase 2 and Phase 4 quietly smuggle in objects (“Bayesian updates,” “contradiction detection,” “semantic drift”) that will not be defensible without much tighter semantics and evaluation. The structure is fine; the epistemics claims are the fragile part.

## Phase-by-phase coherence

### Phase 1 (Go core migration)

This is coherent and worth doing.

* The package layout is sensible for replacing shell scripts.
* The migration priority order is correct.
* The CLI surface matches your existing workflows.

Two technical corrections:

* Your `Manifest` struct tags say `yaml:"..."` but you described parsing `input_manifest.txt` which is not YAML in your current system; you either need to (a) switch to YAML manifests explicitly, or (b) use `mapstructure`/custom parsing and don’t call it YAML. Mixing them will create silent inconsistencies.
* `trace/types.go` defines `Manifest` inside `trace`, while you also have `pkg/manifest/types.go`. Pick one owner. If `manifest` owns the schema, `trace` should embed/import it.

One design correction:

* Put “domain rules” (role name registry, artifact ID constraints, directory layout) in one place (e.g. `internal/policy` or `pkg/policy`) rather than scattering across `validation/boundary.go`, `quarantine/scanner.go`, etc. Otherwise you’ll recreate the regex patchwork.

### Phase 2 (qualitative epistemics layer)

This is the part that’s currently incoherent under scrutiny.

* The `Claim` and `Evidence` structs are fine as data containers.
* The “Simple Bayesian Updater” is not Bayesian in any defensible sense as written because `Evidence.Weight` is being treated like fractional pseudo-counts without a likelihood model, and you hardcode an implied sample size of 10. That will be attacked immediately, and correctly.
* Evidence types as {supporting, contradicting, neutral} are not sufficient; the core problem is that “supporting” is not a measurement. Bayesian updating needs (P(E \mid H)) vs (P(E \mid \neg H)) or at least a likelihood ratio; otherwise you’re doing heuristic nudging.

If you want something that withstands scrutiny, the minimal defensible alternative is:

* Treat each evidence event as a **likelihood ratio** (or log-likelihood ratio) and update in log-odds:
  [
  \text{logit}(p')=\text{logit}(p)+\log\left(\frac{P(E\mid H)}{P(E\mid \neg H)}\right)
  ]
  Then `Evidence` needs either `(p_e_given_h, p_e_given_not_h)` or a single `log_lr`. This becomes auditable and mathematically meaningful.

Claim extraction via regex is fine if it’s explicitly labeled “heuristic candidate extraction.” If you present it as “claim identification,” it will be treated as naive NLP and dismissed.

### Phase 3 (structural fixes: drift metrics + logical parser)

Coherent as an engineering deliverable; epistemically limited.

* Jaccard + edit distance are acceptable as *surface drift* metrics.
* Your “logical form parser” is not a logical form parser; it’s a regex bucketizer for English templates. That’s fine if you name it honestly (e.g. `pattern_forms.go`) and treat outputs as weak signals.
* The contradiction logic (“subject/predicate match + negation flip”) will generate both false positives and false negatives at scale, especially once you leave toy examples.

The scoring/weights in `OverallScore` are arbitrary. If you want scrutiny resistance, you need to:

* separate **metrics** from **decision thresholds**
* justify thresholds empirically on a labeled set (even if it’s your own curated dataset)

### Phase 4 (Obsidian integration)

Engineering-wise: coherent, but the pairwise contradiction scan is (O(n^2)) over claims and will blow up on any nontrivial vault. You’ll need indexing (by subject tokens, by embedding hash buckets, or at least locality-sensitive hashing) even if you keep it “no ML dependencies.”

Also: “vault watch / continuous monitoring” will demand debouncing, caching, and a stable state store, or you’ll flood reports and corrupt trust in the tool.

## Major architectural issues to fix before you code

1. **Define your epistemic object model explicitly**
   Right now you have: markdown artifacts, traces, claims, evidence, contradictions, drift metrics. The relations between them are underspecified. Under scrutiny, you need a tight graph:

* Artifact (text) → Trace (immutable record)
* Trace → ClaimSet (extracted or curated)
* Claim → Predictions (optional, required for scoring)
* Evidence → Update (formal rule)
* Contradictions → Pressure (governance input, not truth signal)

2. **Don’t call heuristic nudges “Bayesian”**
   Either implement likelihood-based updates or call it a heuristic confidence ledger. “Bayesian” is a high-precision word; misusing it will sink credibility faster than anything else.

3. **Separate integrity hash from drift**
   Hash is for tamper evidence. Drift metrics are for change characterization. Never treat Hamming distance of hashes as semantic drift in the new system; your roadmap mostly avoids it, but the `hash/comparison.go` naming still tempts that confusion.

4. **Decide manifest format**
   If you keep text manifests, design a strict parser with canonicalization; if you switch to YAML, commit to YAML everywhere and version the schema.

## Concrete missing pieces for “withstands scrutiny”

* A proper scoring mechanism (Brier/log) tied to predictions.
* A calibration report command that aggregates scores over time.
* A policy registry for valid roles, reserved names, directory contracts.
* A labeled evaluation set for contradiction detection/drift thresholds, even if small and hand-curated.

## Verdict

As a refactor roadmap for turning your bash pipeline into a Go CLI with better correctness and testing: coherent. As a roadmap to a rigorous epistemic instrument: Phase 2’s “Bayesian updater” and Phase 3/4’s “logical form” and “contradiction detection” are conceptually overstated and will not survive technical scrutiny unless you (i) implement likelihood-ratio updating, and (ii) treat language-pattern parsing as weak heuristics with measured error rates. The plan becomes coherent under scrutiny if you rename the heuristic components honestly and make scoring/calibration first-class rather than an implied future feature.


---


That correction makes the plan more coherent. “Continuous monitoring” is a reliability trap: it forces you to solve state, debouncing, partial failure recovery, and repeated false positives before you’ve even validated the epistemic core.

What you actually want is batch-mode runs over a declared snapshot, with explicit triggers.

Replace “watch” with a snapshot + trigger model
Trigger semantics (implementation-agnostic)

Define a vault snapshot as: list of files + their content hashes + a run timestamp + tool version.

An audit run consumes exactly one snapshot and produces one report directory keyed by snapshot hash.

This gives you:

Determinism: same snapshot → same output.

No background process.

Easy provenance: reports correspond to concrete states of the vault.

Reasonable triggers (without “watch”)

You can support multiple triggers later without changing the epistemic layer:

Manual

epistemic vault audit /path/to/vault

Most robust; simplest to reason about.

Hooked

Git: run on pre-commit if the vault is a repo.

Obsidian “close” is not a stable cross-platform event, so treat it as UX sugar, not a dependency.

“Idle” batch

A wrapper script that runs when no files changed for N minutes (implemented outside the core, optional).

Still batch-mode; no resident daemon.

Architectural change to reflect this

In Phase 4, replace:

vault watch
with:

vault snapshot

vault audit --snapshot <id>

vault report --snapshot <id>

And store artifacts like:

vault_runs/
  <snapshot_hash>/
    snapshot.json
    claims.json
    contradictions.json
    report.md
    metrics.json

Why this matters epistemically

A big part of your project’s credibility is that it resists self-deception and procedural theater. Daemons and “always-on” monitoring create ambiguity (“what state was it in when it produced this?”). Snapshot runs create auditability.

Analytically: moving from continuous monitoring to explicit snapshot-triggered batch runs eliminates a large class of statefulness and provenance failure modes and makes the system’s outputs reproducible and defensible.