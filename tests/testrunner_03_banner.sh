#!/bin/bash
# Test: Banner y mensaje inicial se muestran
. "$(dirname "$0")/lib.sh"

echo "=== Test 03: Banner ==="
out=$(run_script -h)

assert_contains "$out" "____" "Banner ASCII se muestra"
assert_contains "$out" "Escáner automático" "Mensaje escáner"
assert_contains "$out" "v2" "Indica versión 2"
