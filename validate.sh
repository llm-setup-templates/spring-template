#!/usr/bin/env bash
set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=== spring-template placeholder leak check ==="

# Check config/code files for unreplaced placeholders.
#
# Allowlist: files that intentionally contain {{RUNTIME_KEY}} placeholders
# which the downstream user/agent fills in during SETUP.md Phase 0 or later.
# Each entry is a path (relative to TEMPLATE_DIR) whose placeholders are
# accepted by design. Adding an entry here is a deliberate choice — do NOT
# add a file just to silence a leak; fix the leak unless it is truly
# runtime-configurable.
ALLOWLIST=(
  "examples/aws/task-definition.json"    # ECS task def — all ARNs/IDs are user-input
  "examples/settings.gradle.kts"         # rootProject.name = {{PROJECT_NAME}}
  "examples/archunit/ArchitectureTest.java"  # TODO marker: {{BASE_PACKAGE}}
)

ALL_LEAKS=$(grep -rl '{{[A-Z_][A-Z0-9_]*}}' "$TEMPLATE_DIR" \
  --include="*.kts" --include="*.yml" \
  --include="*.yaml" --include="*.json" --include="*.java" \
  --include="*.xml" \
  --exclude-dir=".git" \
  2>/dev/null || true)

LEAKS_FILTERED=""
while IFS= read -r path; do
  [ -z "$path" ] && continue
  rel="${path#$TEMPLATE_DIR/}"
  allowed=0
  for a in "${ALLOWLIST[@]}"; do
    if [ "$rel" = "$a" ]; then
      allowed=1
      break
    fi
  done
  if [ "$allowed" -eq 0 ]; then
    LEAKS_FILTERED="${LEAKS_FILTERED}${path}"$'\n'
  fi
done <<< "$ALL_LEAKS"

LEAKS_FILTERED="${LEAKS_FILTERED%$'\n'}"

if [ -n "$LEAKS_FILTERED" ]; then
  echo "FAIL (non-allowlisted files): Unreplaced placeholders detected:"
  echo "$LEAKS_FILTERED"
  echo ""
  echo "Specific placeholder values found:"
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    grep -Hn '{{[A-Z_][A-Z0-9_]*}}' "$path"
  done <<< "$LEAKS_FILTERED"
  echo ""
  echo "If a flagged file genuinely needs runtime placeholders, add its"
  echo "relative path to the ALLOWLIST array at the top of validate.sh."
  exit 1
fi

echo "Allowlisted runtime-placeholder files (by design): ${#ALLOWLIST[@]}"

echo "PASS: No unreplaced placeholders in config/code files."
echo ""
echo "=== spring-template required file existence check ==="

REQUIRED_FILES=(
  "SETUP.md"
  "CLAUDE.md"
  "README.md"
  ".claude/rules/code-style.md"
  ".claude/rules/architecture.md"
  ".claude/rules/git-workflow.md"
  ".claude/rules/verification-loop.md"
  ".claude/skills/claude-md-reviewer/SKILL.md"
  "examples/build.gradle.kts"
  "examples/settings.gradle.kts"
  "examples/checkstyle/checkstyle.xml"
  "examples/checkstyle/suppressions.xml"
  "examples/spotbugs/spotbugs-exclude.xml"
  "examples/archunit/ArchitectureTest.java"
  "examples/config/AppProperties.java"
  "examples/.springjavaformatconfig"
  "examples/application.yml"
  "examples/application-local.yml"
  "examples/Dockerfile"
  "examples/.dockerignore"
  "examples/docker-compose.yml"
  "examples/aws/task-definition.json"
  "examples/ci.yml"
  "examples/.commitlintrc.json"
  "examples/.coderabbit.yaml"
)

MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$TEMPLATE_DIR/$f" ]; then
    echo "MISSING: $f"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -gt 0 ]; then
  echo "FAIL: $MISSING required file(s) missing."
  exit 1
fi

echo "PASS: All $((${#REQUIRED_FILES[@]})) required files exist."
echo ""
echo "=== ci.yml step order check ==="

CI_FILE="$TEMPLATE_DIR/examples/ci.yml"
CHECKOUT_LINE=$(grep -n "actions/checkout@v4" "$CI_FILE" | head -1 | cut -d: -f1)
COMMITLINT_LINE=$(grep -n "wagoid/commitlint" "$CI_FILE" | head -1 | cut -d: -f1)

if [ "$CHECKOUT_LINE" -lt "$COMMITLINT_LINE" ]; then
  echo "PASS: checkout@v4 (line $CHECKOUT_LINE) is before commitlint (line $COMMITLINT_LINE)."
else
  echo "FAIL: commitlint appears before checkout in ci.yml!"
  exit 1
fi

# Check fetch-depth: 0
if grep -q "fetch-depth: 0" "$CI_FILE"; then
  echo "PASS: fetch-depth: 0 present in ci.yml."
else
  echo "FAIL: fetch-depth: 0 missing from ci.yml checkout step!"
  exit 1
fi

PASS=0
FAIL=0

pass() { echo "PASS [$1] $2"; PASS=$((PASS + 1)); }
fail() { echo "FAIL [$1] $2"; FAIL=$((FAIL + 1)); }

check_absent() {
  local id="$1" desc="$2" file="$3" pattern="$4"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then
    fail "$id" "$desc — forbidden pattern found in $file: $pattern"
  else
    pass "$id" "$desc (forbidden pattern absent)"
  fi
}

check_present_eq() {
  local id="$1" desc="$2" actual="$3" expected="$4"
  if [ "$actual" = "$expected" ]; then
    pass "$id" "$desc (got: $actual)"
  else
    fail "$id" "$desc (expected: $expected, got: $actual)"
  fi
}

check_gte() {
  local id="$1" desc="$2" actual="$3" minimum="$4"
  if [ "$actual" -ge "$minimum" ]; then
    pass "$id" "$desc (got: $actual >= $minimum)"
  else
    fail "$id" "$desc (expected >= $minimum, got: $actual)"
  fi
}

echo ""
echo "=== V9: regression guards (PR #6 Java + format + rule count + dependabot) ==="
check_absent "V9a" "SETUP.md uses javaVersion=17 (not 21)" \
  "$TEMPLATE_DIR/SETUP.md" "javaVersion=21"
check_absent "V9b" "SETUP.md Prerequisites: JDK >= 17 (not 21)" \
  "$TEMPLATE_DIR/SETUP.md" "JDK >= 21"
check_absent "V9c" "SETUP.md Pinned Versions: Java 17 (not 21)" \
  "$TEMPLATE_DIR/SETUP.md" "Java \(Temurin\) \| 21"
check_absent "V9d-1" "CLAUDE.md uses spring-java-format 0.0.47 (not 0.0.43)" \
  "$TEMPLATE_DIR/CLAUDE.md" 'spring-java-format 0\.0\.43'
check_absent "V9d-2" ".claude/rules/code-style.md uses spring-java-format 0.0.47 (not 0.0.43)" \
  "$TEMPLATE_DIR/.claude/rules/code-style.md" 'spring-java-format 0\.0\.43'
check_present_eq "V9e" "ArchitectureTest.java JavaDoc claims 12 rules" \
  "$(grep -c 'All 12 rules' "$TEMPLATE_DIR/examples/archunit/ArchitectureTest.java" 2>/dev/null || echo 0)" "1"

echo ""
echo "=== V10: build files consistent with documentation ==="
V10_BUILD=$(grep -c "JavaLanguageVersion.of(17)" "$TEMPLATE_DIR/examples/build.gradle.kts" 2>/dev/null || echo 0)
V10_CI=$(grep -c "java-version: '17'" "$TEMPLATE_DIR/examples/ci.yml" 2>/dev/null || echo 0)
V10_PLUGIN=$(grep -c '0\.0\.47' "$TEMPLATE_DIR/examples/build.gradle.kts" 2>/dev/null || echo 0)
check_gte "V10a" "build.gradle.kts uses Java 17 toolchain" "$V10_BUILD" "1"
check_gte "V10b" "ci.yml uses java-version: '17'" "$V10_CI" "1"
check_gte "V10c" "build.gradle.kts pins spring-java-format 0.0.47" "$V10_PLUGIN" "1"

echo ""
echo "=== V11: Phase 5.5 Core files present ==="
for f in \
  .github/ISSUE_TEMPLATE/feature.yml \
  .github/ISSUE_TEMPLATE/bug.yml \
  .github/ISSUE_TEMPLATE/adr.yml \
  .github/ISSUE_TEMPLATE/config.yml \
  .github/PULL_REQUEST_TEMPLATE.md \
  .github/CODEOWNERS \
  .github/workflows/validate.yml \
  docs/README.md \
  docs/requirements/RTM.md \
  docs/requirements/_FR-template.md \
  docs/architecture/overview.md \
  docs/architecture/decisions/README.md \
  docs/architecture/decisions/_ADR-template.md \
  docs/architecture/decisions/_RFC-template.md \
  .claude/rules/documentation.md; do
  if [ -f "$TEMPLATE_DIR/$f" ]; then
    pass "V11" "$f"
  else
    fail "V11" "$f missing"
  fi
done

echo ""
echo "=== V12: ADR template encodes 5-state lifecycle ==="
V12_STATES=0
for state in Proposed Accepted Rejected Deprecated Superseded; do
  if grep -q "$state" "$TEMPLATE_DIR/docs/architecture/decisions/README.md" 2>/dev/null; then
    V12_STATES=$((V12_STATES + 1))
  fi
done
check_present_eq "V12" "ADR lifecycle states" "$V12_STATES" "5"

echo ""
echo "=== V13: PR template has required discipline sections ==="
V13_REFS=0
for pattern in "FR:" "ADR:" "RTM discipline" "Balancing Rule"; do
  if grep -q "$pattern" "$TEMPLATE_DIR/.github/PULL_REQUEST_TEMPLATE.md" 2>/dev/null; then
    V13_REFS=$((V13_REFS + 1))
  fi
done
check_present_eq "V13" "PR template references (FR / ADR / RTM / Balancing)" "$V13_REFS" "4"

echo ""
echo "=== V14: Reports opt-in module consistency ==="
if [ -d "$TEMPLATE_DIR/docs/reports" ]; then
  V14_FILES=0
  for f in README.md _spike-test-template.md _benchmark-template.md _api-analysis-template.md _paar-template.md; do
    if [ -f "$TEMPLATE_DIR/docs/reports/$f" ]; then
      V14_FILES=$((V14_FILES + 1))
    fi
  done
  check_present_eq "V14" "Reports module completeness (all 5 files)" "$V14_FILES" "5"
else
  echo "SKIP [V14] Reports module not installed"
fi

echo ""
echo "=== V15: Briefings opt-in module consistency ==="
if [ -d "$TEMPLATE_DIR/docs/briefings" ]; then
  V15_FILES=0
  for f in README.md _template/CLAUDE.md _template/README.md _template/slide-outline.md _template/talking-points.md _template/decisions-checklist.md _template/open-questions.md; do
    if [ -f "$TEMPLATE_DIR/docs/briefings/$f" ]; then
      V15_FILES=$((V15_FILES + 1))
    fi
  done
  check_present_eq "V15" "Briefings module completeness (all 7 files)" "$V15_FILES" "7"
else
  echo "SKIP [V15] Briefings module not installed"
fi

echo ""
echo "=== V16: Extended opt-in module consistency ==="
V16_PRESENT=0
for f in docs/architecture/containers.md docs/architecture/DFD.md docs/data/dictionary.md; do
  if [ -f "$TEMPLATE_DIR/$f" ]; then
    V16_PRESENT=$((V16_PRESENT + 1))
  fi
done
if [ "$V16_PRESENT" = "3" ]; then
  pass "V16" "Extended module installed (3/3)"
elif [ "$V16_PRESENT" = "0" ]; then
  echo "SKIP [V16] Extended module not installed"
else
  fail "V16" "Extended module partial: $V16_PRESENT/3 — must be all or none"
fi

echo ""
echo "=== V17: Dependabot configuration present (.github + examples snapshot) ==="
if [ -f "$TEMPLATE_DIR/.github/dependabot.yml" ]; then
  pass "V17a" ".github/dependabot.yml exists"
else
  fail "V17a" ".github/dependabot.yml missing"
fi
if [ -f "$TEMPLATE_DIR/examples/dependabot.yml" ]; then
  pass "V17b" "examples/dependabot.yml exists"
else
  fail "V17b" "examples/dependabot.yml missing"
fi

echo ""
echo "======================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

echo ""
echo "=== All checks passed ==="
