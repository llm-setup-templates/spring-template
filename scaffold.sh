#!/usr/bin/env bash
# scaffold.sh — Convert a freshly-cloned spring-template into a project-specific scaffold.
#
# Usage:
#   bash ./scaffold.sh --project-name <hyphen-case> --base-package <dotted> \
#                      [--doc-modules core[,reports,briefings,extended]] [--dry-run]
#
# This script is single-use. It must be run on a freshly cloned template
# (detected via presence of validate.sh). After execution, it self-deletes.
#
# See ADR-002 for architecture rationale (offline Initializr seed +
# Stage A-H 8-stage pipeline).

# ────────────────────────────────────────────────────────────────
# Bash interpreter guard [Fix 8 / Phase 13 Python lineage]
# Windows PowerShell can invoke `./scaffold.sh` via .sh file association
# without actually running bash — exit 0 with no side effects. That silent
# success is more dangerous than a visible failure. This guard refuses to
# run under any non-bash interpreter and instructs the user to prefix `bash `.
# Note: PowerShell's `.\scaffold.sh` form bypasses this guard entirely
# (ShellExecute path doesn't parse the script body). See RATIONALE.md
# § PowerShell Silent-No-Op for the empirical test matrix.
# ────────────────────────────────────────────────────────────────
# BASH_VERSION: bash-only shell variable (dash/ash/zsh/PowerShell do not set it).
# BASH: bash-only shell variable holding the full path to the bash binary.
# Checking BOTH closes the M-03 edge case where a parent PowerShell process
# exports BASH_VERSION into the environment and a non-bash child inherits it.
_not_bash=0
[ -z "${BASH_VERSION:-}" ] && _not_bash=1
[ -z "${BASH:-}" ] && _not_bash=1
case "${BASH##*/}" in
  bash|bash.exe) ;;
  *) _not_bash=1 ;;
esac
if [ "$_not_bash" -eq 1 ]; then
  echo "ERROR: scaffold.sh must be executed by Bash." >&2
  echo "       Detected: non-bash interpreter (likely PowerShell/cmd/sh/dash)." >&2
  echo "       Fix: run with an explicit bash prefix:" >&2
  echo "         bash ./scaffold.sh --project-name <name> --base-package <pkg>" >&2
  echo "       On Windows, prefer Git Bash or WSL over PowerShell." >&2
  exit 1
fi
unset _not_bash

set -euo pipefail

# ────────────────────────────────────────────────────────────────
# parse_args
# ────────────────────────────────────────────────────────────────
PROJECT_NAME=""
BASE_PACKAGE=""
DOC_MODULES="core"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $0 --project-name <hyphen-case> --base-package <dotted> [options]

Required:
  --project-name <name>   Project name in hyphen-case (e.g. my-spring-app)
  --base-package <pkg>    Java base package in dotted lowercase (e.g. com.example.myapp)

Optional:
  --doc-modules <list>    comma-separated from {core,reports,briefings,extended}
                          default: core. 'core' is mandatory.
  --dry-run               Print planned actions without writing.
  -h, --help              This message.

Examples:
  bash ./scaffold.sh --project-name my-spring-app --base-package com.example.myapp
  bash ./scaffold.sh --project-name acme-portal --base-package io.acme.portal --doc-modules core,reports
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name)  PROJECT_NAME="$2"; shift 2 ;;
    --base-package)  BASE_PACKAGE="$2"; shift 2 ;;
    --doc-modules)   DOC_MODULES="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               echo "ERROR: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# ────────────────────────────────────────────────────────────────
# validate args
# ────────────────────────────────────────────────────────────────
if [[ -z "$PROJECT_NAME" ]]; then
  echo "ERROR: --project-name is required" >&2
  usage >&2
  exit 1
fi

if [[ -z "$BASE_PACKAGE" ]]; then
  echo "ERROR: --base-package is required" >&2
  usage >&2
  exit 1
fi

if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "ERROR: --project-name must be hyphen-case (lowercase, starts with letter, letters/digits/hyphens)" >&2
  echo "       got: '$PROJECT_NAME'" >&2
  exit 1
fi

if ! [[ "$BASE_PACKAGE" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$ ]]; then
  echo "ERROR: --base-package must be dotted lowercase (e.g., com.example.myapp)" >&2
  echo "       got: '$BASE_PACKAGE'" >&2
  exit 1
fi

# doc-modules: must include 'core'; each item must be in {core,reports,briefings,extended}
if [[ ",$DOC_MODULES," != *",core,"* ]]; then
  echo "ERROR: --doc-modules must include 'core' (got '$DOC_MODULES')" >&2
  exit 1
fi
IFS=',' read -ra DOC_MODS_ARR <<<"$DOC_MODULES"
for m in "${DOC_MODS_ARR[@]}"; do
  case "$m" in
    core|reports|briefings|extended) ;;
    *) echo "ERROR: unknown doc module '$m' (valid: core,reports,briefings,extended)" >&2; exit 1 ;;
  esac
done

# Derived variables
PROJECT_NAME_LOWER="$(echo "$PROJECT_NAME" | tr -d '-')"
BASE_PACKAGE_PATH="$(echo "$BASE_PACKAGE" | tr '.' '/')"

# ────────────────────────────────────────────────────────────────
# freshness check — validate.sh is template-only; its presence is the
# reliable marker that scaffold.sh has not yet run.
# ────────────────────────────────────────────────────────────────
if [[ ! -f validate.sh ]]; then
  echo "ERROR: validate.sh not found — this doesn't look like a freshly-cloned template." >&2
  echo "       scaffold.sh is single-use. Re-clone the template to start over:" >&2
  echo "         git clone https://github.com/llm-setup-templates/spring-template <new-dir>" >&2
  exit 1
fi

# ────────────────────────────────────────────────────────────────
# plan summary
# ────────────────────────────────────────────────────────────────
echo "==============================================="
echo " scaffold.sh — spring-template"
echo "==============================================="
echo " PROJECT_NAME       : $PROJECT_NAME"
echo " PROJECT_NAME_LOWER : $PROJECT_NAME_LOWER"
echo " BASE_PACKAGE       : $BASE_PACKAGE"
echo " BASE_PACKAGE_PATH  : $BASE_PACKAGE_PATH"
echo " DOC_MODULES        : $DOC_MODULES"
echo " DRY_RUN            : $DRY_RUN"
echo "==============================================="
if [[ $DRY_RUN -eq 1 ]]; then
  echo " (dry-run: no files will be modified)"
fi
echo ""

# ────────────────────────────────────────────────────────────────
# helpers: execute-or-echo (dry-run aware)
# ────────────────────────────────────────────────────────────────
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

run_eval() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    eval "$*"
  fi
}

substitute() {
  # Portable in-place substitution (GNU sed + BSD sed compatible).
  local pattern="$1" replacement="$2" file="$3"
  if [[ ! -f "$file" ]]; then
    echo "  WARN: substitute skip (file not found): $file"
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] substitute '$pattern' -> '$replacement' in $file"
  else
    sed "s|$pattern|$replacement|g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

# helper: migrate_initializr_seed_package
# rev.2/rev.3: Handles only the Initializr seed's com.example.template.
# All other examples/* assets carry {{BASE_PACKAGE}} placeholders that the
# generic 'find src' sed in Stage D substitutes uniformly.
migrate_initializr_seed_package() {
  local old_dir="src/main/java/com/example/template"
  local new_dir="src/main/java/$BASE_PACKAGE_PATH"
  local old_test_dir="src/test/java/com/example/template"
  local new_test_dir="src/test/java/$BASE_PACKAGE_PATH"

  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$new_dir" "$new_test_dir"
    if [[ -d "$old_dir" ]]; then
      # Edge case: if old_dir == new_dir (user --base-package=com.example.template),
      # mv would self-overwrite. Skip the rename in that case — files are already in place.
      if [[ "$old_dir" != "$new_dir" ]]; then
        mv "$old_dir"/* "$new_dir/" 2>/dev/null || true
        rmdir "$old_dir" 2>/dev/null || true
        rmdir src/main/java/com/example 2>/dev/null || true
        rmdir src/main/java/com 2>/dev/null || true
      fi
    fi
    if [[ -d "$old_test_dir" ]]; then
      if [[ "$old_test_dir" != "$new_test_dir" ]]; then
        mv "$old_test_dir"/* "$new_test_dir/" 2>/dev/null || true
        rmdir "$old_test_dir" 2>/dev/null || true
        rmdir src/test/java/com/example 2>/dev/null || true
        rmdir src/test/java/com 2>/dev/null || true
      fi
    fi
    # Initializr seed package declarations (TemplateApplication.java +
    # TemplateApplicationTests.java) — substitute com.example.template → $BASE_PACKAGE
    find src -type f -name '*.java' -print0 | while IFS= read -r -d '' f; do
      sed "s|com\.example\.template|$BASE_PACKAGE|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  else
    echo "  [dry-run] migrate_initializr_seed_package: com.example.template → $BASE_PACKAGE"
  fi
}

# ────────────────────────────────────────────────────────────────
# Stage A — remove template-only files
#   scaffold.sh is NOT in this list (self-deletes in Stage H).
# ────────────────────────────────────────────────────────────────
echo "[Stage A] Remove template-only files"
TEMPLATE_ONLY=(
  validate.sh
  .github/workflows/validate.yml
  .github/dependabot.yml
  examples/dependabot.yml
  test
  RATIONALE.md
  CODERABBIT-PROMPT-GUIDE.md
  docs/architecture/decisions/ADR-002-clone-script-scaffolding.md
  # .claude/ : KEEP — derived repo reuses agent rules
  # examples/ : KEEP until Stage F
  # scaffold.sh : self-delete in Stage H
)
for f in "${TEMPLATE_ONLY[@]}"; do
  if [[ -e "$f" ]]; then
    run rm -rf "$f"
  fi
done

# ────────────────────────────────────────────────────────────────
# Stage B — single archetype (no-op for Spring)
# ────────────────────────────────────────────────────────────────
echo "[Stage B] Single archetype (web-mvc) — no selection needed"

# ────────────────────────────────────────────────────────────────
# Stage C — copy archetype + shared configs
#   Order: Initializr seed FIRST (provides gradlew, default src/main),
#          then template-specific assets OVERWRITE Initializr defaults.
# ────────────────────────────────────────────────────────────────
echo "[Stage C] Copy archetype files to repo root"

# Initializr seed (provides gradlew, gradle/wrapper/, default src/, .gitignore, .gitattributes, HELP.md)
run_eval "cp -a examples/initializr-seed/. ."

# Template-specific build files OVERWRITE Initializr defaults
run cp examples/build.gradle.kts .
run cp examples/settings.gradle.kts .
run cp examples/.springjavaformatconfig .
run cp examples/.commitlintrc.json .
run cp examples/.coderabbit.yaml .

# Static analysis configs
run cp -r examples/checkstyle .
run cp -r examples/spotbugs .

# Docker + AWS deployment
run cp examples/Dockerfile .
run cp examples/.dockerignore .
run cp examples/docker-compose.yml .
run mkdir -p aws
run cp examples/aws/task-definition.json aws/

# CI/CD
run mkdir -p .github/workflows
run cp examples/ci.yml .github/workflows/ci.yml
run cp examples/dependabot.yml .github/dependabot.yml

# Spring application configs
run mkdir -p src/main/resources
run cp examples/application.yml src/main/resources/
run cp examples/application-local.yml src/main/resources/
run cp examples/application-dev.yml src/main/resources/
run mkdir -p src/test/resources
run cp examples/application-test.yml src/test/resources/application.yml

# Logback — copy single file to root resources/ (NOT the directory).
# Spring Boot only auto-loads src/main/resources/logback-spring.xml at root.
# Sub-directory placement (resources/logback/logback-spring.xml) silently fails.
run cp examples/logback/logback-spring.xml src/main/resources/logback-spring.xml

# Application-layer Java classes — copy under $BASE_PACKAGE_PATH
run mkdir -p "src/main/java/$BASE_PACKAGE_PATH/config"
run cp examples/config/AppProperties.java "src/main/java/$BASE_PACKAGE_PATH/config/"

run mkdir -p "src/main/java/$BASE_PACKAGE_PATH/support/error"
run_eval "cp examples/support/error/*.java \"src/main/java/$BASE_PACKAGE_PATH/support/error/\""

run mkdir -p "src/main/java/$BASE_PACKAGE_PATH/support/response"
run_eval "cp examples/support/response/*.java \"src/main/java/$BASE_PACKAGE_PATH/support/response/\""

run mkdir -p "src/main/java/$BASE_PACKAGE_PATH/core/api/support"
run cp examples/core/api/support/ApiControllerAdvice.java "src/main/java/$BASE_PACKAGE_PATH/core/api/support/"

# ArchUnit test
run mkdir -p "src/test/java/$BASE_PACKAGE_PATH/architecture"
run cp examples/archunit/ArchitectureTest.java "src/test/java/$BASE_PACKAGE_PATH/architecture/"
run cp examples/archunit/archunit.properties src/test/resources/

# ────────────────────────────────────────────────────────────────
# Stage D — substitute placeholders
# ────────────────────────────────────────────────────────────────
echo "[Stage D] Substitute placeholders"

# CLAUDE.md
substitute '{{PROJECT_NAME}}' "$PROJECT_NAME" CLAUDE.md
substitute '{{PROJECT_ONE_LINER}}' "_(fill in your project description)_" CLAUDE.md

# Build files
substitute '{{PROJECT_NAME}}' "$PROJECT_NAME" settings.gradle.kts

# AWS task-definition (9 placeholders → dummy values for CI-green)
substitute '{{AWS_ACCOUNT_ID}}'              '000000000000'                                                       aws/task-definition.json
substitute '{{AWS_REGION}}'                  'us-east-1'                                                          aws/task-definition.json
substitute '{{TASK_EXECUTION_ROLE_ARN}}'     'arn:aws:iam::000000000000:role/dummy-task-exec'                    aws/task-definition.json
substitute '{{TASK_ROLE_ARN}}'               'arn:aws:iam::000000000000:role/dummy-task'                         aws/task-definition.json
substitute '{{SECRET_ARN_DB_USER}}'          'arn:aws:secretsmanager:us-east-1:000000000000:secret:dummy-db-user' aws/task-definition.json
substitute '{{SECRET_ARN_DB_PASSWORD}}'      'arn:aws:secretsmanager:us-east-1:000000000000:secret:dummy-db-pass' aws/task-definition.json
substitute '{{RDS_ENDPOINT}}'                'localhost'                                                          aws/task-definition.json
substitute '{{DB_NAME}}'                     'appdb'                                                              aws/task-definition.json
substitute '{{PROJECT_NAME}}'                "$PROJECT_NAME"                                                      aws/task-definition.json

# BASE_PACKAGE substitution across all Java/yml/xml in src/
# T11에서 examples/* 자산이 모두 {{BASE_PACKAGE}} placeholder 보유 → 단일 sed로 처리.
# rev.4 (R3-2 High): dry-run 가드 추가 — 직접 sed 호출은 dry-run 분기 명시 필요.
if [[ $DRY_RUN -eq 0 ]]; then
  find src -type f \( -name '*.java' -o -name '*.yml' -o -name '*.xml' \) -print0 | while IFS= read -r -d '' f; do
    sed "s|{{BASE_PACKAGE}}|$BASE_PACKAGE|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
else
  echo "  [dry-run] substitute {{BASE_PACKAGE}} -> $BASE_PACKAGE in src/**/*.{java,yml,xml}"
fi

# Migrate Initializr seed package (com.example.template → $BASE_PACKAGE)
migrate_initializr_seed_package

# ────────────────────────────────────────────────────────────────
# Stage E — trim unselected doc modules
# ────────────────────────────────────────────────────────────────
echo "[Stage E] Trim doc modules (kept: $DOC_MODULES)"

has_module() {
  [[ ",$DOC_MODULES," == *",$1,"* ]]
}

if ! has_module "reports"; then
  run rm -rf docs/reports
fi
if ! has_module "briefings"; then
  run rm -rf docs/briefings
fi
if ! has_module "extended"; then
  run rm -f docs/architecture/containers.md docs/architecture/DFD.md
  run rm -rf docs/data
fi

# ────────────────────────────────────────────────────────────────
# Stage F — remove examples/ + cleanup Initializr defaults
# ────────────────────────────────────────────────────────────────
echo "[Stage F] Remove examples/ + cleanup Initializr defaults"
run rm -rf examples
# rev.3 (Round 2 CX-6): Initializr seed application.properties conflicts
# with template's application.yml — both auto-loaded by Spring Boot.
run rm -f src/main/resources/application.properties

# ────────────────────────────────────────────────────────────────
# Stage G — reinit git (fresh history)
# ────────────────────────────────────────────────────────────────
echo "[Stage G] Reinit git (fresh history)"
run rm -rf .git
run git init -b main
# rev.3 (Round 2 I-5/CX-1): no `git update-index --chmod=+x gradlew` here.
# Reason: empty index after `git init` → update-index would fail (or no-op).
# Exec bit is preserved through (1) template-side baking (gradlew is staged
# as 100755 in spring-template's git index) + (2) cp -a in Stage C
# preserving fs bit + (3) user's `git add gradlew` re-staging the bit.

# ────────────────────────────────────────────────────────────────
# Stage H — report + self-delete
# ────────────────────────────────────────────────────────────────
echo ""
echo "==============================================="
echo " ✓ scaffold complete"
echo "==============================================="
cat <<EOF

Next steps:
  1) Format + verify:
       ./gradlew format
       ./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar

  2) Commit the scaffold:
       git add .
       git commit -m "feat(scaffold): initial project setup"

  3) (Optional) Publish to GitHub:
       gh auth status
       gh repo create $PROJECT_NAME --private --source=. --remote=origin
       git push -u origin main
       # If 'git push' does not trigger CI on a brand-new repo, fire manually:
       gh workflow run ci.yml --ref main

⚠ TODO before production:
  - .github/CODEOWNERS — replace @YOUR_ORG/* placeholders with real team handles
  - aws/task-definition.json — replace dummy ARNs (000000000000) with real AWS values
  - Application class name (e.g., TemplateApplication.java) — IDE rename for cosmetic
    correctness (optional; build works as-is)
  - Add @EnableConfigurationProperties(AppProperties.class) OR @ConfigurationPropertiesScan
    annotation to your Application class so AppProperties is registered.
    See AppProperties.java JavaDoc for example.

EOF

# Self-delete scaffold.sh.
# On Linux/macOS the inode is preserved until the process closes, so
# rm -- "\$0" succeeds from within the running script. On Windows Git Bash
# the file is locked; we emit a warning and ask the user to delete manually.
if [[ $DRY_RUN -eq 0 ]]; then
  if rm -- "$0" 2>/dev/null; then
    :
  else
    echo "⚠ Could not auto-remove scaffold.sh (likely Windows file lock)."
    echo "  Delete manually: rm scaffold.sh"
  fi
fi

exit 0
