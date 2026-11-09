#!/bin/sh
# Runs the log size check from disk_check.mod on an oversized log.
# Usage: tests/test_disk_check_log_size.sh [path/to/disk_check.mod]
S="$(cd "$(dirname "${1:-amtm_modules/disk_check.mod}")" && pwd)/$(basename "${1:-amtm_modules/disk_check.mod}")"
T="${TMPDIR:-/tmp}/pr-test.$$"; mkdir -p "$T" || exit 1; trap 'rm -rf "$T"' EXIT; rc=0; cd "$T" || exit 1
ok() { echo "PASS $1"; }; no() { echo "FAIL $1"; rc=1; }
check() { if eval "$2"; then ok "$1"; else no "$1"; fi; }

awk '/wc -c < \$CHKLOG/{p=1} p{print} p&&/^[[:space:]]*fi$/{exit}' "$S" > trim.sh
logger() { :; }; CHKLOG=log; TAG=test
line=$(awk 'BEGIN { while (n++ < 999) printf "x" }')
i=0; while [ "$i" -lt 400 ]; do echo "$line"; i=$((i + 1)); done > log; echo newest >> log
. ./trim.sh
check "log is back under the limit" "[ \"\$(wc -c < log | tr -d ' ')\" -lt 100000 ]"
check "newest lines are kept" "grep -q newest log"
check "truncation is noted" "grep -q 'Truncated log file' log"
check "no temp file is left" "[ ! -e log.tmp ]"
exit $rc
