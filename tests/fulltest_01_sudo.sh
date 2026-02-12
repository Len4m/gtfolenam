#!/bin/bash
# Test: Detecta binario en sudo - ejecutar en contenedor fulltest como usuario auditor
# El contenedor tiene: auditor puede ejecutar /usr/local/bin/find con sudo NOPASSWD
. "$(dirname "$0")/lib.sh"

echo "=== Test 01: Sudo (find NOPASSWD) ==="
out=$(run_script -t sudo 2>&1)

assert_contains "$out" "Archivos con sudo" "Muestra sección sudo"
assert_contains "$out" "/usr/local/bin/find" "DEBE encontrar find en lista sudo"
assert_contains "$out" "sin contraseña" "Indica NOPASSWD"
assert_contains "$out" "gtfobins.org/gtfobins/find" "Enlace correcto a GTFOBins find"
