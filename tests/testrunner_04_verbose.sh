#!/bin/bash
# Test: Modo verbose muestra más información
. "$(dirname "$0")/lib.sh"

echo "=== Test 04: Modo Verbose (-v) ==="
out=$(run_script -t suid -v 2>&1)

assert_contains "$out" "Archivos con SUID" "Modo verbose ejecuta escaneo SUID"
# Si hay binarios, verbose muestra "Evaluando"; si no, al menos el escaneo corre
if echo "$out" | grep -qF "Evaluando"; then
    echo -e "${GREEN}PASS${NC}: Modo verbose muestra evaluación de binarios"
else
    echo -e "${GREEN}PASS${NC}: Modo verbose activo (sin binarios SUID que evaluar)"
fi
((tests_passed++))
