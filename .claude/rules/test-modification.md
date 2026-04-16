# Test Modification Rules — Spring Boot / JUnit 5

## When to modify tests

Every code change MUST be accompanied by corresponding test changes.
Use this table to determine which test layers are affected:

| Code Change Type | Affected Test Layer | Required Action |
|-----------------|--------------------|-----------------| 
| REST endpoint added | unit + integration + ArchUnit (auto) | Create controller unit test + `@WebMvcTest` integration test |
| Service method signature changed | unit (direct) + integration (indirect) | Update existing assertions and mocks |
| JPA entity / DB schema changed | integration (Testcontainers) | Update test fixtures, verify migration with H2/TC |
| Business logic modified | unit | Update assertions, add edge case tests |
| Dependency version bumped | integration (may break) | Run full `./gradlew test`, check for API changes |
| Config / property changed | integration + smoke | Update `application-test.yml` fixtures |
| **Refactoring (behavior unchanged)** | **none** | **Do NOT modify tests — if they break, the refactoring is wrong** |

## Test modification checklist (5 steps)

For every code change, follow this sequence:

1. **Identify affected layers** — Use the mapping table above. If unsure, err on the side of more layers.
2. **Run existing tests first** — `./gradlew test` before any test changes. This establishes which tests break from your code change vs. which were already broken.
3. **Modify tests to match new behavior** — Update assertions, mocks, fixtures. Add new test classes for new functionality. Follow the AAA pattern (Arrange-Act-Assert) or Given-When-Then.
4. **Run verification loop** — Full `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar`.
5. **Review test diff** — `git diff src/test/` must make sense relative to the code change. If the test diff is larger than the code diff, reconsider your approach.

## ArchUnit boundary tests

ArchUnit rules run as part of `./gradlew test`. They enforce:
- Controller → Service → Repository layering
- No direct entity returns from controllers (use DTOs)
- Package boundary violations

**These tests should NEVER be modified to accommodate code changes.** If ArchUnit fails:
- The code change violates the architecture → fix the code, not the rule
- Exception: adding a NEW rule for a new architectural constraint is acceptable

## Test profiles and configuration

- **Unit tests**: No Spring context needed. Use `@ExtendWith(MockitoExtension.class)` + `@Mock`/`@InjectMocks`.
- **Integration tests**: Use `@SpringBootTest` + `@ActiveProfiles("test")`. Config in `application-test.yml`.
- **Testcontainers**: For DB-dependent tests, use `@Container` with PostgreSQL. Check `docker compose up -d` or rely on `@ServiceConnection`.

## Matching existing project patterns

Before creating new test files:

- **Check test directory structure**: `src/test/java/com/example/{module}/` — follow existing package layout.
- **Check test patterns**: some projects use `@WebMvcTest` (sliced), others use `@SpringBootTest` (full context). Match what exists.
- **Check assertion style**: AssertJ (`assertThat(...).isEqualTo(...)`) vs. JUnit assertions (`assertEquals`). This template uses **AssertJ**.
- **Check naming convention**: `{ClassName}Test.java` for unit, `{ClassName}IntegrationTest.java` for integration.

## Prohibitions

- **No modifying ArchUnit rules to pass code** — fix the architecture violation
- **No deleting tests to make CI green** — fix the code or update the test correctly
- **No `@SuppressWarnings` to hide test failures** — these mask real bugs
- **No `@Disabled` / `@Ignore`** without a documented reason and issue link
- **Refactoring PRs must not change test assertions** — if a test breaks during refactoring, the refactoring changed behavior
- **No `@SpringBootTest` for pure unit tests** — use Mockito directly; Spring context is expensive

## New feature test requirements

When adding a new feature (endpoint, service, repository):

- **Minimum**: 1 unit test covering the happy path + 1 edge case
- **Controller**: `@WebMvcTest` with `MockMvc` + mocked service
- **Service**: Mockito unit test with mocked repository
- **Repository**: `@DataJpaTest` or Testcontainers integration test
- Follow package convention: `src/test/java/com/example/{module}/`
