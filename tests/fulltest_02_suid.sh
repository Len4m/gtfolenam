#!/bin/bash
# Test: Detecta binario SUID vulnerable - contenedor fulltest tiene find con 4755
. "$(dirname "$0")/lib.sh"

echo "=== Test 02: SUID (find vulnerable) ==="
out=$(run_script -t suid 2>&1)

assert_contains "$out" "Archivos con SUID" "Muestra sección SUID"
assert_contains "$out" "find" "DEBE encontrar binario find"
assert_contains "$out" "gtfobins.org/gtfobins/find" "Enlace correcto a GTFOBins find"
