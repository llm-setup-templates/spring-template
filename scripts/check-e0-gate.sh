#!/usr/bin/env bash
# scripts/check-e0-gate.sh -- Phase E0 pilot gate verification
#
# 5 criteria (Q11=A LOCK):
#   1. V_drift PASS (validate.sh full run, includes V_seed-ddd)
#   2. ApplicationModules.verify() PASS (Spring Modulith)
#   3. ArchUnit 4 DDD rule (DddArchitectureTest only) PASS
#   4. Order Testcontainers test count >= 4 PASS (JUnit XML count, not Gradle text)
#   5. phase-e-pr-template.md SHA256 == 14a-bis baked value (byte-identical inheritance)
#
# Run AFTER E0 pilot PR merge to confirm gate before Phase E (python+typescript).

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
ARCHETYPE_DIR="$ROOT/examples/archetype-ddd-pilot"
EXPECTED_PR_TEMPLATE_SHA256="8f46c4c99ff9aafe5983d4e8fff4c7589649aaf4cb1281c1eca7f561c53e842a"

echo "=== E0 Gate Preflight: Docker check ==="
if ! docker info > /dev/null 2>&1; then
    echo "FAIL: Docker not available -- Testcontainers requires Docker"
    exit 1
fi
echo "Docker OK"

cd "$ARCHETYPE_DIR"

echo ""
echo "=== E0 Gate Step 1/5: validate.sh full run (V_seed-ddd included) ==="
bash "$ROOT/validate.sh"
echo "Step 1 OK"

echo ""
echo "=== E0 Gate Step 2/5: ApplicationModules.verify() PASS ==="
./gradlew test --tests "*ApplicationModulesTest" --rerun-tasks
echo "Step 2 OK"

echo ""
echo "=== E0 Gate Step 3/5: ArchUnit 4 DDD rule (DddArchitectureTest) PASS ==="
./gradlew test --tests "*DddArchitectureTest" --rerun-tasks
echo "Step 3 OK"

echo ""
echo "=== E0 Gate Step 4/5: Order Testcontainers test count >= 4 PASS (JUnit XML) ==="
./gradlew test \
    --tests "*OrderServiceTest" --tests "*OrderControllerTest" \
    --rerun-tasks
TESTCASE_COUNT=$(find build/test-results/test -name "*OrderServiceTest*.xml" -o -name "*OrderControllerTest*.xml" 2>/dev/null \
    | xargs grep -h "<testcase" 2>/dev/null | wc -l)
FAILURE_COUNT=$(find build/test-results/test -name "*OrderServiceTest*.xml" -o -name "*OrderControllerTest*.xml" 2>/dev/null \
    | xargs grep -hE "<failure|<error" 2>/dev/null | wc -l)
PASSED_COUNT=$((TESTCASE_COUNT - FAILURE_COUNT))
echo "  test cases: $TESTCASE_COUNT, failures/errors: $FAILURE_COUNT, passed: $PASSED_COUNT"
if [ "$PASSED_COUNT" -lt 4 ]; then
    echo "FAIL: Order Testcontainers passed count < 4: $PASSED_COUNT"
    exit 1
fi
echo "Step 4 OK"

echo ""
echo "=== E0 Gate Step 5/5: phase-e-pr-template.md SHA256 == 14a-bis baked value ==="
ACTUAL_SHA256=$(sha256sum "$ROOT/docs/templates/phase-e-pr-template.md" | awk '{print $1}')
echo "  expected: $EXPECTED_PR_TEMPLATE_SHA256"
echo "  actual:   $ACTUAL_SHA256"
if [ "$ACTUAL_SHA256" != "$EXPECTED_PR_TEMPLATE_SHA256" ]; then
    echo "FAIL: phase-e-pr-template.md SHA256 mismatch -- 14a-bis byte-identical inheritance violated"
    exit 1
fi
echo "Step 5 OK"

echo ""
echo "==========================================="
echo "E0 GATE PASS: 5/5"
echo "Phase E (python+typescript) entry granted."
echo "==========================================="
