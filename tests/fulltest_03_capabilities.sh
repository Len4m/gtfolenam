#!/bin/bash
# Test: Detecta binario con capabilities - fulltest usa tmpfs + setcap como root
# Python en /cap-test/python tiene cap_setuid, el escáner debe encontrarlo
. "$(dirname "$0")/lib.sh"

echo "=== Test 03: Capabilities (python cap_setuid) ==="
out=$(run_script -t capabilities 2>&1)

assert_contains "$out" "Archivos con capabilities" "Muestra sección capabilities"
assert_contains "$out" "python" "DEBE encontrar python con capabilities"
assert_contains "$out" "gtfobins.org/gtfobins/python" "Enlace correcto a GTFOBins python"
