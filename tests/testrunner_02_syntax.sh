#!/bin/bash
# Test: Sintaxis correcta del script
. "$(dirname "$0")/lib.sh"

echo "=== Test 02: Sintaxis ==="
if bash -n "$GTFOLENAM" 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}: Sintaxis bash correcta"
    ((tests_passed++))
else
    echo -e "${RED}FAIL${NC}: Errores de sintaxis en el script"
    ((tests_failed++))
fi
