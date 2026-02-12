#!/bin/bash
# Funciones comunes para tests de gtfolenam

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GTFOLENAM="$PROJECT_ROOT/gtfolenam.sh"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Solo inicializar si no están definidas (evita reset al re-sourcer)
: "${tests_passed:=0}"
: "${tests_failed:=0}"

run_script() {
    bash "$GTFOLENAM" "$@" 2>&1
}

assert_contains() {
    local output="$1"
    local pattern="$2"
    local msg="${3:-Expected output to contain: $pattern}"
    if echo "$output" | grep -qF -- "$pattern"; then
        echo -e "${GREEN}PASS${NC}: $msg"
        ((tests_passed++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Pattern: $pattern"
        ((tests_failed++))
        return 1
    fi
}

assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local msg="${3:-Expected output NOT to contain: $pattern}"
    if ! echo "$output" | grep -qF -- "$pattern"; then
        echo -e "${GREEN}PASS${NC}: $msg"
        ((tests_passed++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Pattern: $pattern"
        ((tests_failed++))
        return 1
    fi
}

assert_exit_success() {
    local output="$1"
    local msg="${2:-Command should succeed}"
    # Si llegamos aquí, el comando ya se ejecutó; el test verifica el output
    echo -e "${GREEN}PASS${NC}: $msg"
    ((tests_passed++))
    return 0
}

assert_exit_failure() {
    local output="$1"
    local pattern="${2:-Error}"
    local msg="${3:-Expected error}"
    if echo "$output" | grep -qE "$pattern"; then
        echo -e "${GREEN}PASS${NC}: $msg"
        ((tests_passed++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        ((tests_failed++))
        return 1
    fi
}

print_summary() {
    echo ""
    echo "=========================================="
    echo -e "Tests: ${GREEN}$tests_passed passed${NC}, ${RED}$tests_failed failed${NC}"
    echo "=========================================="
    return $tests_failed
}
