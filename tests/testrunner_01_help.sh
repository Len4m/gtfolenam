#!/bin/bash
# Test: -h muestra ayuda correcta
. "$(dirname "$0")/lib.sh"

echo "=== Test 01: Ayuda (-h) ==="
out=$(run_script -h)

assert_contains "$out" "Uso:" "Muestra línea de uso"
assert_contains "$out" "Opciones:" "Muestra sección opciones"
assert_contains "$out" "-v" "Muestra opción -v"
assert_contains "$out" "-h" "Muestra opción -h"
assert_contains "$out" "-t" "Muestra opción -t"
assert_contains "$out" "-u" "Muestra opción -u"
assert_contains "$out" "sudo" "Muestra tipo sudo"
assert_contains "$out" "suid" "Muestra tipo suid"
assert_contains "$out" "capabilities" "Muestra tipo capabilities"
assert_contains "$out" "GTFOBins" "Menciona GTFOBins"
