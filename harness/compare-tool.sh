#!/bin/sh
# compare-tool.sh <tool> <corpus.in>
#
# Runs the given tool via BOTH heirloom-*-darwin (native) and apout+V7
# (emulated PDP-11 V7 binary), captures both outputs, diffs, records
# the result in reports/.
#
# Prerequisites (both must be present or the harness skips):
#   /opt/heirloom/bin/<tool>              — the Heirloom port binary
#   /opt/heirloom/upstream-ancestors/v7/  — extracted V7 tape
#   /opt/heirloom/vendor/apout/apout      — Apout emulator (see APOUT-STATUS.md)
#
set -eu
TOOL="$1"
IN="$2"
: "${PREFIX:=/opt/heirloom}"

HEIR_BIN="$PREFIX/bin/$TOOL"
V7_BIN="$PREFIX/upstream-ancestors/v7/usr/bin/$TOOL"
APOUT="$PREFIX/vendor/apout/apout"

if [ ! -x "$HEIR_BIN" ]; then
    echo "  SKIP $TOOL: no heirloom binary at $HEIR_BIN"; exit 0
fi
if [ ! -f "$V7_BIN" ]; then
    echo "  SKIP $TOOL: no V7 binary at $V7_BIN"; exit 0
fi
if [ ! -x "$APOUT" ]; then
    echo "  SKIP $TOOL: apout not built (see APOUT-STATUS.md)"; exit 0
fi

REPORT="reports/${TOOL}-$(basename "$IN" .in).diff"
mkdir -p reports

"$HEIR_BIN" < "$IN" > /tmp/heir.out 2>/tmp/heir.err
"$APOUT" "$V7_BIN" < "$IN" > /tmp/v7.out 2>/tmp/v7.err

if diff -q /tmp/heir.out /tmp/v7.out >/dev/null 2>&1; then
    echo "  PASS $TOOL: outputs identical"
    echo "PASS" > "$REPORT"
else
    diff -u /tmp/v7.out /tmp/heir.out > "$REPORT" || true
    echo "  DRIFT $TOOL: see $REPORT"
fi
