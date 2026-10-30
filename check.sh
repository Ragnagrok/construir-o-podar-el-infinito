#!/usr/bin/env bash
# Builds everything, checks that the demo prints exactly expected-output.txt
# (the candidate streams are deterministic), and runs the QuickCheck tests.
set -euo pipefail
cd "$(dirname "$0")"

cabal build all --enable-tests -v0
echo "ok   the library, the demo and the tests compile"

if diff <(cabal run demo -v0) expected-output.txt; then
  echo "ok   the demo prints expected-output.txt"
else
  echo "FAIL the demo's output changed (diff above)"; exit 1
fi

cabal test -v0 --test-show-details=direct
