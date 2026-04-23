# Code Style Rules

## Universal
- Indent size: 4
- Line length limit: 120
- Trailing commas: none (Java does not use trailing commas)
- End of line: LF (enforced via .gitattributes)
- File encoding: UTF-8

## Formatter ownership
- The formatter (spring-java-format 0.0.47) owns all whitespace / layout concerns.
- The linter (Checkstyle 10.17.0 (Google Java Style base)) owns semantic / logic rules only.
- Style rules that conflict between the two must be disabled in the linter (see `checkstyle/suppressions.xml`).

## Naming
- Classes: PascalCase (`UserService`, `OrderController`)
- Methods and fields: camelCase (`findByEmail`, `userId`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)
- Layer suffix enforced: `*Controller`, `*Service` or `*UseCase`, `*Repository`
- Test classes: suffix `Test` or `IT` (integration test)

## Imports
- No wildcard imports (`import com.example.*` prohibited)
- Import ordering managed by spring-java-format — do not configure separately in Checkstyle (suppressed in `checkstyle/suppressions.xml`)
- `jakarta.*` preferred over `javax.*` (Spring Boot 3 / Jakarta EE 9+)
- Static imports grouped at the end of import block
