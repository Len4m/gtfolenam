#!/bin/bash
# Test: Script funciona con busybox como fallback - contenedor solo tiene busybox
# Debe encontrar find SUID (busybox find) y reportarlo
. "$(dirname "$0")/lib.sh"

echo "=== Test 01: fallback y find SUID ==="
out=$(run_script -t suid 2>&1)

assert_contains "$out" "Archivos con SUID" "Funciona con herramientas busybox"
assert_not_contains "$out" "Error: Se necesita" "No debe fallar por falta de herramientas"
assert_contains "$out" "find" "DEBE encontrar find SUID (busybox)"
assert_contains "$out" "gtfobins.org" "Enlace GTFOBins presente"
