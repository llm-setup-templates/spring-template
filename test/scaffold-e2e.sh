#!/usr/bin/env bash
# E2E test for scaffold.sh. Usage: bash test/scaffold-e2e.sh [doc-modules]
#
# Copies the template to a temp dir (portable cp -a, no rsync), runs
# scaffold.sh with the given doc-modules combo, then verifies post-conditions.
# When Gradle is available, runs ./gradlew compileJava compileTestJava test
# to guard against scaffolded-output regressions.
#
# 5 doc-modules combos covered by .github/workflows/validate.yml matrix:
#   core | core,reports | core,briefings | core,extended | core,reports,briefings,extended

set -euo pipefail

DOC_MODULES="${1:-core}"
case "$DOC_MODULES" in
  'core'|'core,reports'|'core,briefings'|'core,extended'|'core,reports,briefings,extended') ;;
  *) echo "[e2e] invalid doc-modules: $DOC_MODULES" >&2
     echo "       valid: core | core,reports | core,briefings | core,extended | core,reports,briefings,extended" >&2
     exit 1 ;;
esac

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d -t scaffold-e2e-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "[e2e] template     : $TEMPLATE_ROOT"
echo "[e2e] tmpdir       : $TMPDIR"
echo "[e2e] doc-modules  : $DOC_MODULES"

# 1. Copy template WITHOUT .git and test/ (portable, no rsync dependency)
DERIVED="$TMPDIR/e2e-test"
mkdir -p "$DERIVED"
cp -a "$TEMPLATE_ROOT/." "$DERIVED/"
rm -rf "$DERIVED/.git" "$DERIVED/test"

cd "$DERIVED"

# 2a. Runtime guard check (Linux only — uses dash if available, since dash
# is POSIX shell without BASH_VERSION). Skipped on Windows Git Bash.
if command -v dash >/dev/null 2>&1; then
  if dash scaffold.sh --project-name dummy --base-package com.example.dummy >/dev/null 2>&1; then
    echo "FAIL: dash invocation succeeded — guard ineffective"
    exit 1
  fi
  test -f validate.sh || { echo "FAIL: dash partially scaffolded (validate.sh gone)"; exit 1; }
  test -f scaffold.sh || { echo "FAIL: dash removed scaffold.sh"; exit 1; }
  echo "[e2e] runtime guard PASS — dash invocation rejected, template unchanged"
else
  echo "[e2e] dash not available — skipping runtime guard check (covered by V22 static + CI Linux)"
fi

# 2b. Run scaffold.sh (real)
bash scaffold.sh --project-name e2e-test --base-package com.example.e2etest --doc-modules "$DOC_MODULES"

# 3. Structural post-conditions
test -f build.gradle.kts        || { echo "FAIL: build.gradle.kts missing"; exit 1; }
test -f settings.gradle.kts     || { echo "FAIL: settings.gradle.kts missing"; exit 1; }
grep -q 'rootProject.name = "e2e-test"' settings.gradle.kts \
  || { echo "FAIL: settings.gradle.kts {{PROJECT_NAME}} not substituted"; exit 1; }
test -d "src/main/java/com/example/e2etest" \
  || { echo "FAIL: BASE_PACKAGE dir missing"; exit 1; }
test -f "src/main/java/com/example/e2etest/config/AppProperties.java" \
  || { echo "FAIL: AppProperties.java in BASE_PACKAGE missing"; exit 1; }
test -f "src/test/java/com/example/e2etest/architecture/ArchitectureTest.java" \
  || { echo "FAIL: ArchitectureTest.java in BASE_PACKAGE missing"; exit 1; }
# Round 2 CX-3/I-2: support/response Critical fix
test -f "src/main/java/com/example/e2etest/support/response/ApiResponse.java" \
  || { echo "FAIL: ApiResponse.java missing — Round 2 CX-3 regression"; exit 1; }
test -f "src/main/java/com/example/e2etest/support/response/ResultType.java" \
  || { echo "FAIL: ResultType.java missing"; exit 1; }
# Round 2 CX-2/I-3: ArchitectureTest @AnalyzeClasses + Rule 6 substituted
grep -q '@AnalyzeClasses(packages = "com.example.e2etest"' \
  "src/test/java/com/example/e2etest/architecture/ArchitectureTest.java" \
  || { echo "FAIL: ArchitectureTest @AnalyzeClasses still uses raw com.example"; exit 1; }
grep -q '\.resideInAPackage("com.example.e2etest..")' \
  "src/test/java/com/example/e2etest/architecture/ArchitectureTest.java" \
  || { echo "FAIL: ArchitectureTest Rule 6 still uses raw com.example"; exit 1; }
# Round 2 CX-9: logback-spring.xml at root (NOT in sub-dir)
test -f src/main/resources/logback-spring.xml \
  || { echo "FAIL: logback-spring.xml not at root — Spring Boot auto-load fails"; exit 1; }
test ! -d src/main/resources/logback \
  || { echo "FAIL: examples/logback dir leaked into resources/ — CX-9 regression"; exit 1; }
# Round 2 CX-10: logstash-logback-encoder dependency
grep -q "logstash-logback-encoder" build.gradle.kts \
  || { echo "FAIL: logstash-logback-encoder missing — dev/staging/live profile startup fails"; exit 1; }
# Round 2 CX-6: Initializr default application.properties cleanup
test ! -f src/main/resources/application.properties \
  || { echo "FAIL: Initializr application.properties not cleaned up (CX-6)"; exit 1; }
# Round 2 N-1/CX-11: application-dev.yml PostgreSQL URL
grep -q 'jdbc:postgresql' src/main/resources/application-dev.yml \
  || { echo "FAIL: application-dev.yml not PostgreSQL — N-1/CX-11 regression"; exit 1; }
! grep -q 'jdbc:mysql' src/main/resources/application-dev.yml \
  || { echo "FAIL: application-dev.yml still has mysql URL"; exit 1; }
test -f .github/workflows/ci.yml || { echo "FAIL: ci.yml missing"; exit 1; }
test -f gradlew || { echo "FAIL: gradlew missing"; exit 1; }
# Round 3 R3-CX-1: gradlew exec bit verification post-reinit (Linux/macOS only).
# Windows Git Bash uses NTFS which doesn't track POSIX exec bits — cp -a stores
# 100644, so this check would always fail there. CI runs ubuntu-latest, so the
# verification still gates the actual deployment target.
if [[ "$(uname -s)" == Linux* || "$(uname -s)" == Darwin* ]]; then
  git add gradlew
  git ls-files --stage gradlew | grep -q '^100755' \
    || { echo "FAIL: gradlew not staged as 100755 after git add (R3-CX-1)"; exit 1; }
  git rm --cached gradlew >/dev/null 2>&1 || true  # cleanup for downstream tests
else
  echo "[e2e] skipping R3-CX-1 gradlew exec bit check (Windows — NTFS limitation)"
fi

# Template-only files removed by Stage A
test ! -f validate.sh                    || { echo "FAIL: validate.sh leaked (Stage A regression)"; exit 1; }
test ! -f .github/workflows/validate.yml || { echo "FAIL: validate.yml leaked"; exit 1; }
test ! -d examples                       || { echo "FAIL: examples/ not removed (Stage F)"; exit 1; }
test ! -d test                           || { echo "FAIL: test/ leaked"; exit 1; }
test ! -f RATIONALE.md                   || { echo "FAIL: RATIONALE.md leaked"; exit 1; }
test ! -f CODERABBIT-PROMPT-GUIDE.md     || { echo "FAIL: CODERABBIT-PROMPT-GUIDE leaked"; exit 1; }
test ! -f docs/architecture/decisions/ADR-002-clone-script-scaffolding.md \
  || { echo "FAIL: ADR-002 leaked"; exit 1; }

# scaffold.sh self-delete (Linux only)
if [[ "$(uname -s)" == Linux* || "$(uname -s)" == Darwin* ]]; then
  test ! -f scaffold.sh || { echo "FAIL: scaffold.sh not self-removed on Unix"; exit 1; }
fi

# .claude/ preserved (derived repo agent rules)
test -d .claude/rules || { echo "FAIL: .claude/rules missing"; exit 1; }

# 4. Placeholder leak (CRITICAL — Reality + Runtime Contract Lens)
LEAKS=$(grep -rE '\{\{[A-Z_]+\}\}' . --include="*.java" --include="*.kts" --include="*.yml" --include="*.json" --include="*.xml" --include="*.md" 2>/dev/null || true)
if [ -n "$LEAKS" ]; then
  echo "FAIL: placeholder leak detected:"
  echo "$LEAKS"
  exit 1
fi

# 5. AWS dummy ARN substituted (Round 1 I-3 Critical)
grep -q 'arn:aws:iam::000000000000:role/dummy' aws/task-definition.json \
  || { echo "FAIL: AWS dummy ARN not substituted"; exit 1; }

# 6. com.example.demo / com.example.template package leak check (Round 1 I-1 + Stage D migration)
! grep -rE 'com\.example\.demo' src/ \
  || { echo "FAIL: com.example.demo package leak (T11 regression)"; exit 1; }
! grep -rE 'com\.example\.template' src/ \
  || { echo "FAIL: com.example.template package leak (Stage D migrate_initializr_seed_package regression)"; exit 1; }

# 7. doc-modules verification
case "$DOC_MODULES" in
  'core')
    test ! -d docs/reports    || { echo "FAIL: reports leaked under 'core' only"; exit 1; }
    test ! -d docs/briefings  || { echo "FAIL: briefings leaked under 'core' only"; exit 1; }
    test ! -f docs/architecture/containers.md || { echo "FAIL: extended (containers.md) leaked"; exit 1; }
    test ! -f docs/architecture/DFD.md || { echo "FAIL: extended (DFD.md) leaked"; exit 1; }
    test ! -d docs/data       || { echo "FAIL: extended (docs/data/) leaked"; exit 1; }
    ;;
  'core,reports')
    test -d docs/reports      || { echo "FAIL: reports missing under core,reports"; exit 1; }
    test ! -d docs/briefings  || { echo "FAIL: briefings leaked"; exit 1; }
    ;;
  'core,briefings')
    test -d docs/briefings    || { echo "FAIL: briefings missing"; exit 1; }
    test ! -d docs/reports    || { echo "FAIL: reports leaked"; exit 1; }
    ;;
  'core,extended')
    test -f docs/architecture/containers.md || { echo "FAIL: extended (containers.md) missing"; exit 1; }
    test ! -d docs/reports    || { echo "FAIL: reports leaked"; exit 1; }
    ;;
  'core,reports,briefings,extended')
    test -d docs/reports      || { echo "FAIL: reports missing in full combo"; exit 1; }
    test -d docs/briefings    || { echo "FAIL: briefings missing in full combo"; exit 1; }
    test -f docs/architecture/containers.md || { echo "FAIL: extended missing"; exit 1; }
    ;;
esac

# 8. CLAUDE.md PROJECT_NAME + PROJECT_ONE_LINER substitution
grep -q '^# e2e-test' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md PROJECT_NAME not substituted"; exit 1; }
! grep -q '{{PROJECT_NAME}}' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md {{PROJECT_NAME}} placeholder leak"; exit 1; }
# Round 3 R3-5: PROJECT_ONE_LINER substituted
! grep -q '{{PROJECT_ONE_LINER}}' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md PROJECT_ONE_LINER not substituted"; exit 1; }

echo "[e2e] structural checks PASS"

# 9. Gradle lifecycle (most important verification — only if Gradle available)
# Skipped on environments without JDK/Gradle (e.g., minimal CI smoke test).
if [ -x "./gradlew" ]; then
  echo "[e2e] running ./gradlew compileJava compileTestJava test --no-daemon..."
  ./gradlew compileJava compileTestJava test --no-daemon
  echo "[e2e] gradle lifecycle PASS"
else
  echo "[e2e] gradlew not executable — skipping Gradle lifecycle (verify in CI)"
fi

echo "[e2e] PASS: doc-modules=$DOC_MODULES"
