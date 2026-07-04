# Multi-tool modality survey — 2026-07-04

Systematic comparison of common flag semantics across Heirloom
personality variants + Bell Labs Research Unix editions + Darwin's BSD.

Tools surveyed: **`df`**, **`ls`**, **`head`**, **`tail`**, **`grep`**,
**`du`**.

Extends the pattern established in `DRIFT-od-modality-survey.md`.

## Corpus + reproduction

```sh
# Prerequisites
#   /opt/heirloom/bin/<tool>{,/posix,/posix2001,/s42}    Heirloom personality
#   /opt/heirloom/ucb/<tool>                              UCB/BSD variant
#   /opt/heirloom/research/{v8,v9,v10}/<tool>             Research Unix
#   /opt/heirloom/upstream-ancestors/v7/bin/<tool>        V7 (via Apout)
#   /opt/heirloom/vendor/apout/apout                      Apout emulator
#   /usr/bin/<tool>                                        Darwin BSD

# Test corpora
printf 'foo bar\nbaz qux\nfoo baz\nbar bar\n' > /tmp/grep-in.txt
printf 'apple\nbanana\ncherry\ndate\napple\nbanana\napple\n' > /tmp/dup.in
```

---

## `df` — file system usage

### Default output (no flag)

**Real drift** between `default` and `ucb` variants:

- **Heirloom default `bin/df`**:
  ```
  /                  (/dev/disk3s3s1  ):  54530144 blocks 272650720 files
  /dev               (devfs           ):         0 blocks         0 files
  ```
  Traditional SVR4 output. No header line. Blocks + files columns.

- **Heirloom `ucb/df`**:
  ```
  Filesystem              kbytes       used      avail capacity Mounted on
  /dev/disk3s3s1       971350180  944099444   27250736      98% / 
  ```
  BSD-flavour tabular output with header.

- **Darwin `/usr/bin/df`**: matches ucb layout.

**Finding: real historical drift SVR4 vs BSD.** Both correctly preserved.

### `-k` (kbytes) flag

All Heirloom variants + BSD produce identical tabular BSD-style output.
SVR4 `default` variant with `-k` matches the ucb default output.

### `-P` (POSIX portable format)

All variants produce identical 512-byte-block POSIX portable output.

### V7 df via Apout: empty output (Apout syscall gap — `statfs()` or
equivalent not emulated).

---

## `ls` — list directory contents

### Default (no flag) — no drift

All variants (default/posix/posix2001/s42/ucb) produce byte-identical
single-column listings. Modern PDL default behaviour when stdout is not
a TTY.

### `-l` (long format) — **REAL DRIFT between SVR4 and UCB**

- **SVR4 variants** (`bin/ls`, `bin/posix/ls`, etc.):
  ```
  total 8
  drwxr-xr-x   7 nonroot  staff        224 Jul  2 12:58 original-dist
  ```
  Shows owner AND group columns.

- **UCB `ls`**:
  ```
  total 4
  drwxr-xr-x   7 nonroot      224 Jul  2 12:58 original-dist
  ```
  Shows owner ONLY, no group column.

**Two independent divergences visible**:

1. **Group column present in SVR4, absent in UCB**. Classic
   AT&T-vs-Berkeley difference — SVR4 added the group column;
   4.1BSD didn't have it.

2. **`total` line block accounting differs**: SVR4 shows `total 8`
   (in 512-byte blocks); UCB shows `total 4` (in 1024-byte blocks).
   Same disk usage; different block-size convention.

Both are documented, intentional, correctly preserved.

### `-1` (one entry per line)

Byte-identical across all variants when stdout is redirected.

### V7 ls via Apout: empty output (Apout syscall gap — probably `stat()`
or `getdents()` variant).

---

## `head` — first N lines

### Default (no flag)

Prints first 10 lines (POSIX default). Byte-identical across
Heirloom + V8/V10 + BSD.

### `-2` (numeric shortcut, BSD/V8-lineage)

All variants (default, V8, V10, BSD) produce identical output — the
`-N` numeric shortcut is universally understood.

### `-n 2` (POSIX form) — **REAL MODALITY DRIFT**

- **Heirloom default + BSD**: parse correctly, print 2 lines.
- **V8 + V10 head**: return NOTHING (they don't understand `-n`).

**Historical evolution**: V8/V10 supported only the BSD-style `-N`
shortcut. POSIX.2 (1990) added the `-n N` form. Heirloom (SVR4-lineage
which incorporated POSIX) supports both; V8/V10 support only `-N`.

Documented + intentional.

---

## `tail` — last N lines

Symmetric to `head`. Both `tail` and `tail -2` produce byte-identical
output across all variants (Heirloom / V7-via-Apout / V8/V9 / BSD).
No drift.

---

## `grep` — pattern search

### Default (positive match)

Byte-identical across all variants + V7-via-Apout + BSD.

### `-c` (count matches)

- Heirloom variants + BSD: correctly print `2`.
- **V7-via-Apout: empty output** — Apout syscall gap (V7 grep's counter
  path uses a syscall Apout doesn't fully emulate).

### `-n` (with line numbers)

- Heirloom + BSD: correctly print `1:foo bar` + `3:foo baz`.
- **V7-via-Apout: empty output** — same Apout limitation.

### `-v` (invert match)

Byte-identical across all variants including V7-via-Apout.

---

## `du` — disk usage

### Default (no flag) — **UNEXPECTED CROSS-VARIANT DIVERGENCE**

- **Heirloom `posix/du /tmp`, `posix2001/du /tmp`, BSD `du /tmp`**:
  produce `0	/tmp`.
- **Heirloom `default/du /tmp`, `s42/du /tmp`, `ucb/du /tmp`**:
  produce NO OUTPUT.

**Question**: why do SVR4-default and s42 and ucb `du` produce empty
output for `/tmp` while posix/posix2001 and BSD produce a value?

Hypothesis: `/tmp` on Darwin is a symlink to `/private/tmp`. Perhaps
SVR4-default and s42 and ucb variants refuse to follow symlinks silently
without an explicit `-L` or `-H` flag; POSIX variants follow symlinks
by default.

**REAL DRIFT — needs further analysis with `du /var/log` or a
non-symlinked target.**

### `-s` (summary) — **BLOCK-SIZE DRIFT**

- **SVR4 variants** (default/posix/posix2001/s42) + BSD: `224488	.`
- **UCB variant**: `112244	.` (exactly half)

**Documented UCB block-size drift**: same disk usage, different unit
(SVR4 uses 512-byte blocks, UCB uses 1024-byte blocks).

Also correctly preserved.

### `-k` (kbytes)

All variants + BSD produce byte-identical output. When explicitly asked
for kbytes, everyone agrees.

### V7 du via Apout: empty (Apout syscall gap).

---

## Summary matrix

| Tool     | Personality variants        | V8/V9/V10 | V7 via Apout    | BSD    |
| :------- | :-------------------------- | :-------: | :-------------- | :----: |
| `df`     | default vs ucb DIFFER       | n/a (not installed) | Apout gap | matches ucb |
| `ls`     | default vs ucb DIFFER       | n/a | Apout gap | matches ucb |
| `head`   | all agree                   | -n missing | not tested | matches Heirloom |
| `tail`   | all agree                   | agrees | works | matches Heirloom |
| `grep`   | all agree                   | not tested | Apout gap for -c/-n | matches Heirloom |
| `du`     | posix vs default vs ucb DIFFER on `/tmp` (likely symlink); `-s` block size differs by variant | not tested | Apout gap | matches BSD/posix |

## Findings

**F1 (df default output)**: SVR4-lineage default output differs from
BSD-lineage tabular output. Both correctly preserved by their variants.

**F2 (ls -l group column)**: SVR4 shows group column, UCB doesn't.
Documented historical divergence.

**F3 (ls total block size)**: SVR4 uses 512-byte block accounting, UCB
uses 1024-byte. Both correctly preserved.

**F4 (head -n 2 vs -2)**: V8/V10 don't understand `-n`; only the
POSIX-2-adopting Heirloom variants + BSD do. Intentional POSIX.2
evolution.

**F5 (grep -c, -n via Apout)**: Apout syscall gap prevents these flags
working for V7-via-Apout. Not a Heirloom drift.

**F6 (du /tmp default behaviour)**: Multiple Heirloom variants (default,
s42, ucb) produce empty output for `/tmp` while POSIX variants + BSD
produce `0	/tmp`. Possibly symlink-handling divergence. **Needs
further analysis.**

**F7 (du -s block size)**: SVR4 512-byte blocks vs UCB 1024-byte
blocks. Documented drift.

## Comparison with od findings

The pattern from `DRIFT-od-modality-survey.md` holds here too:

- Real intra-Heirloom personality drifts DO exist (df, ls, du) —
  reflecting SVR4-vs-UCB historical divergence.
- Apout syscall gaps recur (V7-via-Apout empty output for `df`, `ls`,
  `grep -c/-n`, `du`).
- Documented historical evolution (V8/V10 `-N` vs POSIX `-n N` for
  `head`) shows up cleanly in cross-vintage comparisons.

## Follow-up work

- **F6 investigation**: rerun `du` against a non-symlinked directory
  and characterise the SVR4-vs-POSIX symlink-following default.
- **Apout syscall coverage**: `df`, `ls`, `grep -c/-n`, `du` all fail
  via Apout — same class of syscall gap. Consolidate under one Apout
  patch series.
- **Extend survey**: `sort`, `wc`, `awk`, `tr`, `cut`, `paste`, `join`.
- **Publish drift catalogue**: rollup of all documented SVR4-vs-UCB,
  V7-vs-V8-vs-SVR4, POSIX-vs-legacy findings into a canonical
  reference.

## Related

- `reports/DRIFT-col-tab-handling.md` — first per-tool drift narrative.
- `reports/DRIFT-od-modality-survey.md` — od-specific survey.
- `moonman81/heirloom-apout-darwin/APOUT-STATUS.md` — Apout roadmap.
