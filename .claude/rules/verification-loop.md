# Verification Loop Rules

## The Loop
After any code change, the agent MUST run the verification loop:

```
./gradlew checkFormat              → format check
./gradlew compileJava compileTestJava  → type check (if applicable)
./gradlew checkstyleMain checkstyleTest    → static analysis (optional — Spring: checkstyle, spotbugs, archunit)
./gradlew spotbugsMain
# (subsumed by STATIC_ANALYSIS above — Checkstyle IS the linter)
./gradlew test                     → tests
./gradlew build bootJar            → build
```

> `STATIC_ANALYSIS` is the optional 6th slot allowing multi-command blocks
> (Gradle's checkstyleMain + spotbugsMain). The lint slot is subsumed by
> static analysis above — Checkstyle IS the linter. No separate lint command.
> Each slot is fail-fast: stop at the first failure.

**Full verify command (single-line shorthand):**
```bash
./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar
```

Execution order is fail-fast: stop at the first failure.

## Agent Self-Verification Rules
1. Never declare a task complete until the full loop passes.
2. If a step fails, fix the root cause — do not bypass with `--no-verify`,
   or skipping tests.
3. After 3 consecutive failed attempts on the same step, escalate to the human
   instead of trying more aggressive fixes.
4. If the loop command itself is broken (infrastructure issue), report the
   infrastructure problem before attempting code fixes.

## CI Parity
The local verification loop MUST match the CI workflow exactly. Any divergence
is a bug in one of them and must be resolved.
