# APOUT-STATUS — status of the Apout Darwin port

`Apout` (Warren Toomey) runs V7 PDP-11 binaries as user-space
processes on modern Unix. Building it on Darwin arm64 is the
prerequisite for `heirloom-tests-darwin`.

## Upstream

- `https://www.tuhs.org/Archive/Applications/Tools/Emulators/Apout/apout2.3beta1.tar.gz`

## Status: NOT YET PORTED

The initial extension pass (2026-07-03) scaffolded this repo but did
not tackle the Apout port itself. Reasons:

1. Estimated 3-5 days of engineering effort per the reduxed-sunsite
   analysis agent; local re-estimate is 5-7 days.
2. Apout is written for late-1990s Unix; expects `<sys/kd.h>`,
   `struct utsname`, K&R prototypes, and PDP-11-specific numeric
   assumptions.
3. Darwin arm64 has 64-bit `long` and different endianness handling.
4. Signal semantics differ between the Apout upstream Linux target
   and Darwin.

## What's needed

- Extract `apout2.3beta1.tar.gz` into `vendor/apout/`.
- Add Darwin arm64 compat headers (analogous to
  `heirloom-vi-darwin/compat/darwin_termio.h`).
- Fix PDP-11 word-size assumptions where they interact with the
  emulator's memory-model code.
- Patch the syscall dispatch to reject or emulate the ~40 V7
  syscalls Apout doesn't currently handle.
- Verify against a V7 `/bin/sort` binary as the first smoke test.

## Alternative: SIMH

The `simh` PDP-11 emulator (Bob Supnik) is available in Homebrew
and runs V7 as a full VM. Higher setup cost but much more mature.
Trade-off: `simh` provides a whole virtual PDP-11; `apout` provides
just a syscall shim. For the harness, `simh` would need extra
scripting to pipe input/output; `apout` would be closer to a
drop-in `#!/apout /bin/sh`-style tool.

Recommendation: try Apout first; fall back to `simh` scripting if the
Apout port becomes too invasive.

## Contributions welcome

If you land a working Apout Darwin arm64 build, PR with:
- Diff series in `vendor/apout/patches/`.
- Updated `APOUT-STATUS.md` reflecting the new baseline.
- First harness run in `reports/`.
