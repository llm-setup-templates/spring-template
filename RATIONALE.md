# RATIONALE — Spring Template Design Notes

> Out-of-band design rationale that doesn't fit in CLAUDE.md (LLM agent rules)
> or SETUP.md (user-facing how-to). Captures the "why" behind non-obvious
> decisions so future maintainers don't relitigate them.

## PowerShell Silent-No-Op — Accepted Limitation

scaffold.sh contains a 3-condition Bash interpreter guard (`BASH_VERSION`,
`$BASH`, basename check) that refuses to run under dash/sh/zsh and prints a
clear error. **This guard cannot fire under PowerShell** because PowerShell's
`.\<filename>` invocation path bypasses the script body entirely:

- For `.ps1` files, PowerShell runs the file as PowerShell script.
- For other extensions (`.sh`, `.bat`, etc.), PowerShell delegates via
  ShellExecute, which on Windows looks up the file association in the
  registry. Git for Windows registers `.sh` to open in a text editor by
  default — not to execute. In headless contexts (CI runners, agent
  sandboxes) where no editor is present, ShellExecute fails silently.
- The script body is never parsed by any shell that could reach the guard.
  Result: PowerShell `.\scaffold.sh ...` exits 0 with no output and no
  scaffolding side effects.

### Empirical Test Matrix (windows-mcp PowerShell, 2026-04-25)

| Invocation | Result | Cause |
|------------|--------|-------|
| `bash ./scaffold.sh --project-name X --base-package Y` (Git Bash) | normal execution | Bash parses script body, guard passes |
| `bash ./scaffold.sh ...` (Linux/WSL) | normal execution | same |
| `dash ./scaffold.sh ...` (Linux) | guard rejects, exit 1 | BASH_VERSION absent → non-bash detected |
| `sh ./scaffold.sh ...` (POSIX sh on Linux) | guard rejects, exit 1 | same |
| `zsh ./scaffold.sh ...` (zsh) | guard rejects, exit 1 | same |
| `.\scaffold.sh ...` (PowerShell on Windows, headless) | **silent no-op (exit 0)** | ShellExecute path; script body never parsed |
| `.\scaffold ...` (PowerShell, no extension) | **silent no-op (exit 0)** | Fix-9 rename hypothesis empirically rejected (2026-04-23) |
| `cmd /c scaffold.sh ...` (Windows cmd) | error: not recognized | cmd has no `.sh` association |

### Fix-9 rename hypothesis (rejected, 2026-04-23)

Hypothesis: rename `scaffold.sh` → `scaffold` (no extension) to force
PowerShell's `.\<name>` form into a different code path that might reach the
script body.

Empirical test (windows-mcp PowerShell): identical silent no-op. Rejected
in ~5 minutes of testing. ShellExecute's behavior is determined by file
association lookup, not extension presence. The cleaner solution is
documentation, not rename gymnastics.

### Why this is accepted (not fixed)

PowerShell's invocation semantics are outside our control. The two
alternatives — (a) ship a parallel `scaffold.ps1` that duplicates all 8
stages in PowerShell idiom, or (b) require users to invoke via `bash` only —
have very different cost profiles:

- (a) Doubles the maintenance burden, and PowerShell's substitution helpers
  (`Get-Content -Raw -replace ...`) have different semantics from sed
  (regex flavor, line endings, encoding). Drift between the two scripts
  becomes a failure mode of its own.
- (b) Costs a single line in SETUP.md Quick Start ("Run under Bash, not
  PowerShell") and one Troubleshooting row.

We chose (b). The Bash interpreter guard catches dash/sh/zsh edge cases
where the script body IS parsed and silently misbehaves; PowerShell is
documented as out-of-scope.

## Spring Initializr Offline Seed — Why Not Network Fetch

ADR-002 § Alternatives B documents the rejection of network-fetch. The
short version:

- Codex sandboxes don't have outbound HTTPS to start.spring.io.
- Air-gapped CI runners (corporate, defense, regulated industries) don't either.
- GitLab/Gitea mirrors with proxy-only egress to start.spring.io would
  fail mid-scaffold.

ADR-002's core principle — "scaffold.sh requires only `git` + `bash`" —
forbids any third-party HTTPS dependency. Baking the Initializr output
into `examples/initializr-seed/` is the only solution that preserves
this principle while giving users a working Spring Boot starter.

The cost is staleness: the seed is a snapshot of Spring Boot 3.5.0 at
template v1.1.0 release. As start.spring.io rolls forward, the seed
ages. Mitigations:

1. **scaffold-e2e CI weekly schedule** (`cron: '0 12 * * 1'`) — catches
   build breaks before users do.
2. **SETUP.md Troubleshooting row** — `"Spring Boot version too stale"
   → Re-fetch from start.spring.io`.
3. **Dependabot** still tracks transitive deps in `examples/build.gradle.kts`
   (Spring Boot Gradle Plugin, Checkstyle, SpotBugs, ArchUnit, etc.) so
   the template surface stays fresh independent of the seed.

## Application Class Name Cosmetic Issue

The Initializr seed was fetched with `artifactId=template`, which makes
the generated main class `TemplateApplication.java` at
`com.example.template.TemplateApplication`. After scaffold.sh's Stage D
package directory rename + sed pass, the class ends up at e.g.
`com.acme.foo.TemplateApplication` — functional but not what a user
typing `--project-name acme-portal` would expect.

Why we don't auto-rename the class:

1. Renaming a Java class requires more than `mv` — references in
   `pom.xml`/`build.gradle.kts` `mainClass`, `META-INF/spring-configuration-metadata.json`,
   any `@SpringBootTest` test class names, and JavaDoc `{@link Application}`
   would all need updates. The cost-to-benefit ratio is poor.
2. Spring Boot's bootJar task auto-detects the main class from
   `@SpringBootApplication` annotation, so the class name doesn't affect
   the build artifact's `Start-Class` manifest entry.
3. IDE rename (`Shift+F6` in IntelliJ, `Ctrl+Shift+R` in Eclipse) handles
   all references in one operation, including JavaDoc and resource files.

The SETUP.md Troubleshooting documents this; users who want a clean
class name spend 30 seconds on IDE rename after first checkout.

## gradlew Exec Bit on Windows Git Bash

The `gradlew` wrapper script must be marked executable (`100755` in
git's index) for CI runners on Linux to run it. Windows NTFS doesn't
natively track POSIX exec bits, so git uses its own index metadata.

Phase 13 Python's scaffold.sh originally tried `git update-index --chmod=+x gradlew`
inside scaffold.sh's Stage G, AFTER `git init -b main`. This was rejected
in plan-review-deep Round 2 (CX-1 Critical) because:

1. `git init` creates an empty index. `git update-index` requires the
   file to already be staged, otherwise it errors with
   `fatal: Unable to mark file gradlew`.
2. With `set -euo pipefail`, the error aborts scaffold.sh mid-Stage G,
   leaving the user with a partial scaffold and no `.git` directory.
   Recovery requires re-clone.

The fix was to remove the `git update-index` call entirely. The exec
bit is preserved through two layers instead:

1. **Template-side baking**: when the Initializr seed is added to the
   template repo (T1 in PLAN), the maintainer runs
   `git update-index --chmod=+x examples/initializr-seed/gradlew` once.
   git's index records `100755` for that path. All future
   `git checkout`s of the template (including derived-repo clones)
   inherit the bit.
2. **scaffold.sh Stage C**: `cp -a examples/initializr-seed/. .` preserves
   the filesystem exec bit on Linux/macOS. On Windows Git Bash the
   bit is lost (NTFS limitation) but the next `git add gradlew` in
   the derived repo restores `100755` from git's index metadata.

scaffold-e2e Step 9 verifies this by running
`git add gradlew && git ls-files --stage gradlew | grep '^100755'`.

## Why Single Archetype (Not 3 Like Python)

ref-python ships 3 archetypes — `fastapi`, `library`, `data-science` —
each with a different `pyproject.toml`, `.importlinter` contract, and
`src/` skeleton.

Spring's situation is different:

- Spring Boot starter dependencies (`spring-boot-starter-web`,
  `spring-boot-starter-batch`, `spring-boot-starter-data-jpa`, etc.)
  are composable, not mutually exclusive. A "library" Spring Boot
  project still uses spring-boot-dependencies for version
  management; a "batch" project uses
  `spring-boot-starter-web` + `spring-boot-starter-batch`.
- The architecture rules in `ArchitectureTest.java` (12 rules) target
  layered web-MVC by default — controller/service/repository
  separation, DTO boundary, transaction placement. These rules
  apply to web-mvc but not directly to batch jobs or library
  projects.
- User demand for Spring archetype splits is unmeasured.

We chose to ship single web-mvc archetype for v1.1.0 (this Phase 13b
release) and revisit archetype splits in a future Phase 14b iteration
if user demand surfaces. The scaffold-e2e CI matrix axis is
`doc-modules` (5 combinations) instead of archetypes (1).

## ALLOWLIST Coordination — Why Conditional Entries

The validate.sh `ALLOWLIST` array marks files that intentionally
contain `{{...}}` placeholders. Most entries are unconditional
(known to always have placeholders). Four entries are **conditional**:

- `examples/application.yml`
- `examples/application-local.yml`
- `examples/application-test.yml`
- `examples/application-dev.yml`

These yml files MAY contain `logging.level.com.example: <LEVEL>`
patterns that need to be substituted with `{{BASE_PACKAGE}}` for
the architecture to work in derived repos. Whether they do or
not is determined by grep at execute time:

- If `grep -q 'logging.level.com.example' <file>` returns a hit:
  introduce `{{BASE_PACKAGE}}` placeholder + add file to ALLOWLIST.
- Otherwise: no change to either.

This coordination is enforced by T11's explicit sub-step in
PLAN.md (rev.4). The risk if missed: validate.sh V1 either
false-fails (placeholder present, ALLOWLIST missing) or
silently passes (no placeholder, ALLOWLIST entry vestigial).

Both failure modes are caught by scaffold-e2e Step 5
(post-scaffold placeholder leak grep).
