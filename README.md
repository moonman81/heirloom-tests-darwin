# heirloom-tests-darwin

Live behavioural-comparison harness for the Heirloom Darwin port.

Runs a corpus of test inputs through BOTH `heirloom-*-darwin`
binaries AND the original V7 PDP-11 binaries via the Apout emulator,
diffs the outputs, and catalogues where behaviour has drifted from
the 1979 baseline.

> **Not authoritative.** This is a research harness, not a
> conformance test suite. Drift is not necessarily a bug — many
> "drifts" are intentional SVR4 evolution or POSIX compliance
> additions. The reports show *where* things differ; interpretation
> is up to the reader.

## Status: PARTIAL — Apout Darwin port landed as sibling repo

**PARTIAL.** The Apout Darwin arm64 port HAS been
completed (sender agent estimated 3-5 days; local re-estimate is
5-7 days). This repo ships:

- `corpora/` — 3 sample test inputs (basic-sort, basic-wc, basic-uniq).
- `harness/compare-tool.sh` — the per-tool diff harness.
- `harness/run-all.sh` — bulk-runner over the corpora.
- `APOUT-STATUS.md` — porting notes + what remains.
- `reports/` — empty; populated by first successful harness run.

## Prerequisites (when the harness is actually working)

- **Heirloom Darwin port installed** at `/opt/heirloom/` (see
  `moonman81/heirloom-workspace-darwin`).
- **V7 source extraction** at
  `/opt/heirloom/upstream-ancestors/v7/` (see
  `moonman81/heirloom-ancestors-darwin` HOWTO).
- **Apout emulator built** at `/opt/heirloom/vendor/apout/apout`.
  This is the missing piece.

## Running the harness (once Apout is available)

```sh
git clone https://github.com/moonman81/heirloom-tests-darwin
cd heirloom-tests-darwin
sh harness/run-all.sh
# Inspect reports/
ls reports/
cat reports/sort-basic-sort.diff
```

## Adding a test

```sh
echo "your test input" > corpora/mytest-<tool>.in
sh harness/compare-tool.sh <tool> corpora/mytest-<tool>.in
```

## What the harness demonstrates

- Behavioural fidelity: proof (or disproof) that a Heirloom
  binary preserves V7 semantics.
- Behavioural drift: catalogued cases where SVR4 evolution moved
  a utility away from V7 baseline.
- POSIX compliance drift: cases where the Heirloom `posix2001/`
  variant differs from V7 but for standards-conformance reasons.

## Companion pieces

- **Corpus expansion**: the `corpora/basic-*.in` inputs are minimal.
  A full research harness would cover thousands of test inputs
  per tool + property-based testing.
- **Bidirectional comparison**: this harness compares Heirloom vs
  V7. A companion would compare Heirloom vs POSIX-standard
  reference implementation (nvi, GNU, BSD).
- **Report publishing**: as reports accumulate, the intent is to
  publish a per-tool behavioural-drift catalogue (`reports/*.md`).

## Licence

Scaffolding: zlib, © 2026 moonman81. Test corpora: CC0 unless
otherwise annotated.

## Related repos

- <https://github.com/moonman81/heirloom-workspace-darwin>
- <https://github.com/moonman81/heirloom-ancestors-darwin> (V7 manifest)
- <https://github.com/moonman81/heirloom-manuals-darwin> (32V manuals
  documenting expected V7-lineage behaviour)
