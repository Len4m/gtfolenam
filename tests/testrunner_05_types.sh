#!/bin/bash
# Test: Combinaciones de tipos -t
. "$(dirname "$0")/lib.sh"

echo "=== Test 05: Tipos de escaneo (-t) ==="

# -t=sudo,capabilities
out=$(run_script -t=sudo,capabilities 2>&1)
assert_contains "$out" "capabilities" "Acepta -t=sudo,capabilities"
assert_not_contains "$out" "Tipo desconocido" "No debe haber tipos desconocidos"

# -t suid (sin =)
out=$(run_script -t suid 2>&1)
assert_contains "$out" "SUID" "Acepta -t suid"

# Tipo desconocido
out=$(run_script -t=foo 2>&1)
assert_contains "$out" "desconocido" "Rechaza tipo desconocido"
