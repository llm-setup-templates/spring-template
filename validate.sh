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
  "CHECKMATE-BACKEND-AUDIT.md"
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

echo ""
echo "=== All checks passed ==="
