#!/bin/sh
# run-all.sh — run every (tool, corpus) pair through compare-tool.sh
set -eu
cd "$(dirname "$0")/.."

pass=0; drift=0; skip=0
for corpus in corpora/*.in; do
    tool_hint=$(basename "$corpus" .in | cut -d- -f2)
    for tool in sort wc uniq cat sed nawk head tail sort tr; do
        [ "$tool_hint" = "basic" ] || [ "$tool_hint" = "$tool" ] || continue
        result=$(sh harness/compare-tool.sh "$tool" "$corpus" 2>&1)
        echo "$result"
        case "$result" in
            *PASS*)  pass=$((pass+1)) ;;
            *DRIFT*) drift=$((drift+1)) ;;
            *SKIP*)  skip=$((skip+1)) ;;
        esac
    done
done
echo
echo "SUMMARY: pass=$pass drift=$drift skip=$skip"
