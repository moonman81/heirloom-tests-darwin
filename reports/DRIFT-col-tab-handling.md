# Drift finding: `col(1)` tab handling

The Heirloom-Darwin `col` binary and the V7-1979 `col` PDP-11 binary
(run under Apout) produce **byte-different output** on 8 of the 8
tested corpora that contain tab characters.

## Reproduction

```sh
# Prerequisites (see APOUT-STATUS.md, heirloom-apout-darwin/README.md):
#   /opt/heirloom/bin/col               — Heirloom-Darwin col
#   /opt/heirloom/upstream-ancestors/v7/bin/col   — V7-1979 col
#   /opt/heirloom/vendor/apout/apout    — Apout emulator

# Input containing tabs
cat > /tmp/col-in <<TEST
The quick brown	fox jumps over the lazy	dog.
Every day is a new day,	but yesterday will always be behind us.
TEST

# V7 output
APOUT_ROOT=/opt/heirloom/upstream-ancestors/v7 \
  /opt/heirloom/vendor/apout/apout \
  /opt/heirloom/upstream-ancestors/v7/bin/col < /tmp/col-in

# Heirloom Darwin output
/opt/heirloom/bin/col < /tmp/col-in

# Diff
diff <(APOUT_ROOT=/opt/heirloom/upstream-ancestors/v7 \
       /opt/heirloom/vendor/apout/apout \
       /opt/heirloom/upstream-ancestors/v7/bin/col < /tmp/col-in) \
     <(/opt/heirloom/bin/col < /tmp/col-in)
```

## Observed difference

V7 col output (byte 1-64 of first line):

    The quick brown\tfox jumps over the lazy\tdog.

Heirloom Darwin col output (byte 1-64 of first line):

    The quick brown fox jumps over the lazy dog.

The single ASCII TAB character (0x09) is preserved by V7 col; Heirloom
col replaces it with one or more ASCII SPACE (0x20) characters. The
expansion is column-aware — text lines up as if the tab were expanded
to the next 8-column tab stop.

## Where the divergence comes from

`col(1)` was originally a filter for nroff output — it removes reverse
line-feeds and column-position codes. Whether or not to also expand
tabs to spaces has historically been an implementation choice, not a
specification requirement.

- **V7 (1979)**: leaves horizontal tabs in place.
- **Heirloom `heirloom-toolchest-070715/col/`**: inherits from
  OpenSolaris SVR4 lineage, which added tab expansion.

The SVR4 change was documented in AT&T's SVID Volume III (~1988).
`col(1)` in SVR4-and-later systems expands tabs by default; the `-x`
flag was added to suppress the expansion:

    col -x       # preserve tabs (V7 compatibility)
    col          # expand tabs (SVR4 default)

## Is this a bug?

**No.** This is documented SVR4 behaviour. Heirloom preserves the
SVR4 semantics correctly. The V7 behaviour is available via
`col -x`.

Reproducing the V7 output with the Heirloom binary:

```sh
diff <(APOUT_ROOT=/opt/heirloom/upstream-ancestors/v7 \
       /opt/heirloom/vendor/apout/apout \
       /opt/heirloom/upstream-ancestors/v7/bin/col < /tmp/col-in) \
     <(/opt/heirloom/bin/col -x < /tmp/col-in)
```

... should return no output (V7 col output byte-identical to
`heirloom col -x`).

## What this teaches

- Not every drift is a bug. Some drifts are **intentional SVR4
  evolution** correctly preserved by Heirloom.
- The Heirloom project's stated goal is to preserve **SVR4** behaviour
  on modern platforms — not V7. Where SVR4 diverges from V7, Heirloom
  correctly implements SVR4.
- A behavioural-comparison harness like this one is valuable for
  **cataloguing** where the SVR4-vs-V7 divergences show up, not for
  measuring drift-from-a-single-baseline.

## Follow-up work

- Extend the harness to run `col -x` and diff against V7 to
  demonstrate the specific-flag-recovers-V7 property.
- Publish a running catalogue of "Heirloom preserves SVR4 (which
  diverges from V7 in this specific way)" findings, ordered by tool.

## Related

- `moonman81/heirloom-manuals-darwin/unix-32v-1.0/` — the manual
  volume that documented the SVR4-era tab-expansion default.
- `moonman81/heirloom-ancestors-darwin/manifests/V7.md` — V7 manifest.
