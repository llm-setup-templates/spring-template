# {{PROJECT_NAME}}

> Generated from llm-setup-templates/spring-template.
> Canonical rules body for all agents (Claude Code loads this via CLAUDE.md imports; Codex CLI loads it directly).

## 1. Project Overview
{{PROJECT_ONE_LINER}}

## 2. Tech Stack
- Language: Java 17 (LTS / Temurin) — auto-provisioned by Gradle toolchain (Foojay resolver) so host JDK version does not matter
- Package Manager: Gradle (Kotlin DSL 8.x)
- Formatter: spring-java-format 0.0.47
- Linter: Checkstyle 10.17.0 (Google Java Style) + SpotBugs 4.8.6
- Type Checker: javac (via ./gradlew compileJava — integrated in build)
- Test Runner: JUnit 5 + AssertJ + Mockito + Testcontainers
- CI: GitHub Actions
- PR Review: CodeRabbit

## 3. Primary Commands
- Install deps: `./gradlew dependencies`
- Format check: `./gradlew format` (auto-fix) / `./gradlew checkFormat` (check only)
- Lint: `./gradlew checkstyleMain checkstyleTest`
- Type check: `./gradlew compileJava compileTestJava`
- Test: `./gradlew test`
- Build: `./gradlew build bootJar`
- Full verify: `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar`

## 4. Architecture Summary
See `.agents/rules/architecture.md` for full rules.
This project uses a layered Spring Boot architecture with **team-dodn package naming** for future multi-module migration. Packages: `core.api` (controllers), `core.domain` (business logic), `storage.db` (JPA persistence), `clients` (external APIs), `support` (cross-cutting: error handling, logging). All API responses are wrapped in `ApiResponse<T>` with standardized `ErrorCode` enums. Global exception handling via `@ControllerAdvice` converts `CoreException` to `ApiResponse`. ArchUnit enforces the boundary rules at test time (the rule count lives in `ArchitectureTest.java` only). See `.agents/rules/architecture.md` for full rules.

## 5. Requirements traceability (RTM)

Every functional requirement gets an ID and a row in `docs/requirements/RTM.md`.

- ID formats: `FR-{DOMAIN}-{NNN}` for functional, `NFR-{CATEGORY}-{NNN}` for
  non-functional, `TC-{DOMAIN}-{NNN}` for test cases (all three digits,
  zero-padded). `ORDER` in examples is a placeholder — define your domain
  prefixes in the table at the top of RTM.md. Never reuse a retired number;
  set Status to `Deprecated` instead of deleting the row.
- When a PR implements or changes an FR, update its RTM row **in the same PR**.
  The row links the FR to its issue, ADRs, operationId, component paths,
  and tests (`TC-...` plus the test file path).
- Row completeness follows Status: `Draft`/`Design` rows need only ID, Summary,
  and Status; `Done` rows must list at least one existing component path and
  one existing test path. Any path you do write must exist (except on
  `Deprecated` rows, which keep their historical paths after code removal).
- The `V_rtm` section of `validate.sh` checks ID format, duplicates, the
  status gate above, and that referenced paths exist. If you don't use the
  RTM, the check stays silent; to drop it entirely, delete the `V_rtm`
  section in validate.sh (one block, marked by its header comment).
- Full rules: `.agents/rules/documentation.md`.

## 6. Verification Rules
After any code change, run the full verification loop.
Never declare a task complete until it passes.
See `.agents/rules/verification-loop.md`.

## 7. Test Modification

When modifying code, always update tests in the same commit. Determine affected test layers:

- **Endpoint/service added** → create unit test (`@Mock`) + integration test (`@WebMvcTest` or `@SpringBootTest`)
- **Signature/schema changed** → update existing assertions and mocks
- **Logic modified** → update assertions, add edge cases
- **Dependency bumped** → run full `./gradlew test`, check for API changes
- **Refactoring only** → do NOT touch tests; if they break, the refactoring is wrong
- **ArchUnit fails** → fix the code, never the rule

Full rules and checklist: `.agents/rules/test-modification.md`

## 8. Git Workflow
- Never commit directly to `main`
- Conventional Commits required
- See `.agents/rules/git-workflow.md`

## 9. Business / Domain Terms
N/A — add project-specific terms here as the codebase evolves.
