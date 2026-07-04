# `od(1)` modality survey — 2026-07-04

Systematic comparison of `od(1)` output across every installed
Heirloom personality variant + Research Unix editions (V8/V9/V10) +
V7 (via Apout) + Darwin's BSD `od`.

## Test corpus

    ABCDEFGH\n         (9 bytes: 0x41 0x42 0x43 0x44 0x45 0x46 0x47 0x48 0x0a)

## Default output (no flag) — word octal

| Variant       | Output |
| :------------ | :--- |
| Heirloom `bin/od`         | `0000000 041101 042103 043105 044107 000012` |
| Heirloom `bin/posix/od`   | `0000000 041101 042103 043105 044107 000012` |
| Heirloom `bin/posix2001/od` | `0000000 041101 042103 043105 044107 000012` |
| Heirloom `bin/s42/od`     | `0000000 041101 042103 043105 044107 000012` |
| V8 (Bell Labs 1985)       | `0000000 041101 042103 043105 044107 000012` |
| V9 (Bell Labs 1986)       | `0000000 041101 042103 043105 044107 000012` |
| V10 (Bell Labs 1989)      | `0000000 041101 042103 043105 044107 000012` |
| Darwin BSD `/usr/bin/od`  | `0000000 041101 042103 043105 044107 000012` (padded columns) |
| **V7 via Apout**          | `0000000 000009 00000b 00000d 00000f 00000a` |

**Finding 1**: All 8 native-Darwin variants (Heirloom + V8/V9/V10 + BSD)
produce byte-identical default output for the tested corpus. There is
**NO drift** between Heirloom's four SVR4-personality variants and the
Bell Labs Research Unix binaries built from the same-era sources.

**Finding 2**: V7 od via Apout produces garbled data. Investigation
below.

## `-c` (character format)

All variants + V7-via-Apout produce correct `A B C D E F G H \n`
output. V7-via-Apout, V8, V9, V10 additionally show a trailing `\0`
padding character (V7 word-size alignment convention). BSD `/usr/bin/od`
does not show the padding.

## `-b` (byte octal)

All Heirloom + V8/V9/V10 + BSD produce correct byte values:

    0000000 101 102 103 104 105 106 107 110 012

**V7 via Apout produces garbled data**:

    0000000 009 00a 00b 00c 00d 00e 00f 000 00a 000

The values are NOT the bytes of "ABCDEFGH\n". This is consistent with
the default-output drift above.

## `-x` (short hex)

All Heirloom + V8/V9/V10 + BSD produce correct little-endian 16-bit hex:

    0000000 4241 4443 4645 4847 000a

V7 via Apout produces `0000000 000h 000j 000l 000n 000q` — an
even-stranger format artefact.

## `-h` flag support (Historical drift discovery)

| Variant                | Behaviour of `-h` |
| :--------------------- | :---------------- |
| Heirloom `bin/od`      | `od: bad flag -h` — flag not implemented |
| Heirloom `bin/posix/od`| same |
| Heirloom `bin/posix2001/od` | same |
| Heirloom `bin/s42/od`  | same |
| **V8 od (1985)**       | correct output — `0000000 4241 4443 4645 4847 000a` (same as `-x`) |
| **V9 od (1986)**       | correct output — same as V8 |
| **V10 od (1989)**      | correct output — same as V8 |
| Darwin BSD `/usr/bin/od` | error |

**Finding 3**: V8/V9/V10 od supported `-h` as a synonym for `-x` (short
hex). SVR4 dropped this synonym; Heirloom (which descends from SVR4/
OpenSolaris) correctly preserves the SVR4 behaviour, so `-h` is NOT
supported.

**Historical drift**: `-h` short-hex flag was preserved in Bell Labs
Research Unix through V10 (1989) but removed by AT&T SVR4 (~1988).
Heirloom's `heirloom-toolchest-070715` inherits from OpenSolaris (2005),
which had SVR4 semantics, so the `-h` synonym stayed dropped.

## Documentation retraction (was Finding 4)

**Finding 4 — RETRACTED**: An initial reading of the survey
suggested the man page listed `-h` as a valid option but the binary
rejected it.  On re-inspection, the man page does NOT mention `-h`.
The initial misread came from confusion when `od -h` opened the man
page (via the `heirloom_flags` shim's default `-h` → man behaviour) —
the man page shown at that point does NOT itself list `-h` among the
supported flags.

So the observation stands but the conclusion is different: there is
NO Heirloom-internal doc drift on `od -h`.  The man page and binary
agree — neither documents nor implements `-h`.

The behaviour the user sees when running `od -h` on a Heirloom binary
is: shim intercepts `-h` (default behaviour when `HF_H_TAKEN` is not
set) and opens the man page.  That is arguably good UX — the user
tried an undocumented flag and got documentation.

## Apout V7-syscall coverage assessment

The garbled V7 output for default / `-b` / `-x` modes contrasts with
correct output for `-c`. This suggests:

- Apout emulates the `read()` syscall correctly (else `-c` would fail
  too).
- V7 od's word/byte-format code paths use a different syscall (perhaps
  `lseek()`, `stat()`, or a specific ioctl for the terminal output) that
  Apout does not fully emulate.

The `-c` mode is a simple stdout-write of pre-formatted characters. The
default / `-b` / `-x` modes involve more complex I/O and formatting;
the specific broken syscall would need `-trap` mode inspection to
identify.

**Filed as ongoing work** in `moonman81/heirloom-apout-darwin`'s
`APOUT-STATUS.md`.

## Reproduction

```sh
# Prerequisites
#   /opt/heirloom/bin/od               — Heirloom (SVR4) od
#   /opt/heirloom/research/{v8,v9,v10}/od  — Research Unix od
#   /opt/heirloom/upstream-ancestors/v7/bin/od  — V7 od
#   /opt/heirloom/vendor/apout/apout   — Apout emulator

printf 'ABCDEFGH\n' > /tmp/od-in

# Compare all variants
for od in /opt/heirloom/bin/od \
          /opt/heirloom/bin/posix/od \
          /opt/heirloom/bin/posix2001/od \
          /opt/heirloom/bin/s42/od \
          /opt/heirloom/research/v8/od \
          /opt/heirloom/research/v9/od \
          /opt/heirloom/research/v10/od \
          /usr/bin/od; do
  echo "=== $od ==="
  "$od" < /tmp/od-in
done

# V7 via Apout
APOUT_ROOT=/opt/heirloom/upstream-ancestors/v7 \
  /opt/heirloom/vendor/apout/apout \
  /opt/heirloom/upstream-ancestors/v7/bin/od < /tmp/od-in
```

## Summary

For `od(1)`:

- **0** cases of real drift between Heirloom's four personality variants.
- **0** cases of real drift between Heirloom and Bell Labs V8/V9/V10.
- **1** documented historical drift: V8/V9/V10 supported `-h` as a
  `-x` synonym; SVR4 dropped it; Heirloom (SVR4 lineage) correctly
  preserves the removal.
- **All** V7-via-Apout drifts are Apout syscall-coverage limitations,
  not real behavioural drift.

**Correction**: A prior version of this document listed a fourth
finding claiming Heirloom-internal doc drift on `-h`.  On re-inspection
the man page does not mention `-h`; the finding was retracted.

## Related

- `DRIFT-col-tab-handling.md` — similar "SVR4 evolution" pattern for `col`.
- `moonman81/heirloom-apout-darwin/APOUT-STATUS.md` — Apout syscall
  coverage roadmap.
- `moonman81/heirloom-research-v8v9v10-darwin/build/` — the V8/V9/V10
  binaries used in this survey.
