## Determinism Contract

A trace is reproducible iff:
1. Artifact content bytes are identical
2. `.meta` file exists with identical FSM_WEIGHT/TENSION/COLLAPSE
3. Script version is identical (SHA of encode_artifact.sh)

Violations:
- ❌ Moving artifact to new path without `.meta` → non-deterministic (interactive fallback)
- ❌ Editing `.meta` without Git commit → unversioned state drift

# Determinism Boundary

## Contract
A trace is reproducible iff:
- Artifact content bytes are identical
- `.meta` file exists with identical FSM_WEIGHT/TENSION/COLLAPSE
- Script version matches (SHA of encode/mutate scripts)

## Verification Test
```bash
# Gen1 determinism
./encode_artifact.sh --meta test.md.meta test.md
# → Identical hash on every run

# Mutation determinism
./mutate_artifact.sh test 1 2 --meta test.1-to-2.meta
# → Identical gen2 hash on every run