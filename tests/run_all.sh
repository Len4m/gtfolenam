#!/bin/bash
# Ejecuta TODOS los tests dentro de contenedores Docker.
# Tests robustos que verifican detección real de binarios vulnerables.
# Uso: ./run_all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Se requiere Docker para ejecutar los tests"
    exit 1
fi

cd "$PROJECT_ROOT"

echo "Construyendo imágenes Docker..."
docker build -t gtfolenam-testrunner -f tests/docker/Dockerfile.testrunner . --quiet
docker build -t gtfolenam-fulltest -f tests/docker/Dockerfile.fulltest . --quiet
docker build -t gtfolenam-busybox -f tests/docker/Dockerfile.busybox . --quiet

run_in_container() {
    local image=$1
    local docker_opts="$2"
    local test_list="$3"
    docker run --rm \
        $docker_opts \
        -v "$PROJECT_ROOT:/project:ro" -w /project/tests \
        "$image" bash -c "
            . lib.sh; tests_passed=0; tests_failed=0
            for t in $test_list; do [[ -f \$t ]] && . \$t; done
            print_summary
        " 2>&1
}

echo ""
echo "=== 1. Tests básicos (testrunner) ==="
run_in_container gtfolenam-testrunner "" "testrunner_01_help.sh testrunner_02_syntax.sh testrunner_03_banner.sh testrunner_04_verbose.sh testrunner_05_types.sh testrunner_06_full_scan.sh"

echo ""
echo "=== 2. Tests robustos: sudo + suid + capabilities (fulltest, usuario auditor) ==="
run_in_container gtfolenam-fulltest "--tmpfs /cap-test:mode=0755" "fulltest_01_sudo.sh fulltest_02_suid.sh fulltest_03_capabilities.sh"

echo ""
echo "=== 3. Busybox fallback ==="
run_in_container gtfolenam-busybox "" "busybox_01_suid.sh"
