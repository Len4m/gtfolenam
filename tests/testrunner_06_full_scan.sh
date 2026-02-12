#!/bin/bash
# Test: Escaneo completo (sin -t) ejecuta todos los tipos
. "$(dirname "$0")/lib.sh"

echo "=== Test 06: Escaneo completo ==="
out=$(run_script 2>&1)

assert_contains "$out" "Archivos con" "Ejecuta escaneo"
assert_contains "$out" "SUID" "Incluye SUID"
assert_not_contains "$out" "Error: No hay datos" "Tiene datos GTFOBins"
