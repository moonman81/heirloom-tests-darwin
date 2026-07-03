# APOUT-STATUS — Apout Darwin port is WORKING

**Update 2026-07-03**: The Apout port to Darwin arm64 has been landed.
See `moonman81/heirloom-apout-darwin` for the working port + patches.

## What changed

Original estimate: 5-7 days. Actual effort: **2 patches, ~2 hours**:

1. `defines.h` NEED_INT_N guard extended to skip Darwin (Darwin's
   `<sys/_types.h>` already provides u_int32_t etc.).
2. `Makefile` LDFLAGS drops `-static` (Darwin doesn't ship crt0.o).

## Confirmed working

```sh
APOUT_ROOT=/tmp/v7 ./apout /tmp/v7/bin/echo hello world
# → hello world

APOUT_ROOT=/tmp/v7 ./apout /tmp/v7/bin/cat < input
# → passes stdin through V7 cat correctly.
```

## Not yet working

The following V7 binaries exit 1 via Apout — these are V7 syscall
coverage gaps within Apout itself (documented in Apout's own
`LIMITATIONS` file), NOT Darwin-porting issues:

- `sort`, `wc`, `ls`, `date`, `pwd`, `sh` — some V7 syscall emulated
  as `EPERM`.
- `true` — magic number 060750, an a.out format Apout doesn't parse.

Fixing these requires patching Apout's V7 syscall handler
(`v7trap.c`), not Darwin porting per se.

## Impact on this repo

`heirloom-tests-darwin` can now be promoted from **SCAFFOLD ONLY**
to a **WORKING** live behavioural-comparison harness for the V7
tools Apout supports (initially: echo, cat, tail).

Once V7 sort, wc, etc. get Apout syscall coverage, they'll join.

## Getting the Apout binary

Install it from `moonman81/heirloom-apout-darwin`:

```sh
git clone https://github.com/moonman81/heirloom-apout-darwin
cd heirloom-apout-darwin
# fetch upstream tarball into vendor/
mkdir -p vendor
curl -L https://www.tuhs.org/Archive/Applications/Tools/Emulators/Apout/apout2.3beta1.tar.gz \
    -o vendor/apout2.3beta1.tar.gz
cd vendor && tar xzf apout2.3beta1.tar.gz && cd apout2.3beta1
patch -p1 < ../../patches/0001-defines-h-add-__APPLE__-to-NEED_INT_N-guard.patch
patch -p1 < ../../patches/0002-Makefile-drop-static-flag-for-Darwin.patch
make
# Result: ./apout (~213 KB Mach-O 64-bit arm64)
```

Then in `heirloom-tests-darwin`, set:

```sh
export APOUT=/path/to/heirloom-apout-darwin/vendor/apout2.3beta1/apout
```

before running `harness/run-all.sh`.
