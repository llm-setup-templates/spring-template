# CheckMate Backend Audit

> Generated: 2026-04-14
> Source: `gh api repos/checkmate-smu/checkmate-web-backend/contents/...`

---

## 1. Overview

| Item | Value |
|------|-------|
| Spring Boot version | 3.5.13 |
| Java version | 17 (Temurin, via `toolchain.languageVersion = JavaLanguageVersion.of(17)`) |
| Build DSL | **Groovy DSL** (`build.gradle` — NOT Kotlin DSL) |
| Gradle wrapper | Present (`gradlew`, `gradlew.bat`) |
| Group ID | `com.checkmate` |

---

## 2. Build Config

**Plugins:**
| Plugin | Version |
|--------|---------|
| `java` | built-in |
| `org.springframework.boot` | 3.5.13 |
| `io.spring.dependency-management` | 1.1.7 |
| `com.diffplug.spotless` | 8.2.1 |
| `checkstyle` | built-in (toolVersion = 10.25.0) |
| `com.github.spotbugs` | 6.1.11 |
| `jacoco` | built-in |

**Key Dependencies:**
- `spring-boot-starter-data-jpa`, `spring-boot-starter-security`, `spring-boot-starter-validation`, `spring-boot-starter-web`
- `org.jsoup:jsoup:1.18.3`
- `org.projectlombok:lombok` (compileOnly + annotationProcessor)
- `org.postgresql:postgresql`
- `com.tngtech.archunit:archunit-junit5:1.4.0` (test)
- `spring-boot-testcontainers`, `org.testcontainers:postgresql` (test)

**Spotless config:**
```groovy
spotless {
  java {
    importOrder()
    removeUnusedImports()
    googleJavaFormat()
  }
}
```

---

## 3. Static Analysis

| Tool | Status | Details |
|------|--------|---------|
| **spring-java-format** | NOT FOUND | Using Spotless + googleJavaFormat() instead |
| **Checkstyle** | ✅ Present | toolVersion = 10.25.0, `config/checkstyle/checkstyle.xml`, `checkstyleTest` disabled |
| **SpotBugs** | ✅ Present | toolVersion = 4.9.3, effort = max, reportLevel = medium |
| **ArchUnit** | ✅ Present | archunit-junit5:1.4.0 in test deps |
| **JaCoCo** | ✅ Present | Coverage reporting |

---

## 4. API Docs

| Item | Status |
|------|--------|
| springdoc-openapi | **NOT FOUND** — no springdoc dependency in `build.gradle` |
| @Tag / @Operation | NOT FOUND (springdoc not used) |
| Spring Security on API | ✅ `spring-boot-starter-security` present |

---

## 5. CI Workflow

**File:** `.github/workflows/ci.yml`

| Step | Action/Command |
|------|---------------|
| Checkout | `actions/checkout@v4` (no `fetch-depth` — commitlint gap) |
| Setup Java | `actions/setup-java@v4` distribution=temurin java-version=17 |
| Setup Gradle | `gradle/actions/setup-gradle@v4` |
| Permission | `chmod +x ./gradlew` |
| Format check | `./gradlew spotlessCheck` |
| Checkstyle | `./gradlew checkstyleMain` |
| SpotBugs | `./gradlew spotbugsMain` |
| Test (ArchUnit) | `./gradlew test` |
| Build | `./gradlew build -x test -x checkstyleMain -x spotbugsMain` |

**Current gaps:**
- No `fetch-depth: 0` on checkout → commitlint impossible
- No commitlint step (no `.commitlintrc.json`)
- Java 17 (template uses 21)
- Groovy DSL (template uses Kotlin DSL)
- No springdoc / Swagger UI
- No `compileJava compileTestJava` explicit typecheck step

---

## 6. Delta Analysis

| Item | CheckMate Current | This Template Adds |
|------|------------------|--------------------|
| Spring Boot version | 3.5.13 (Java 17) | 3.3.6 (Java 17 LTS) — same LTS baseline |
| Build DSL | Groovy DSL | **Kotlin DSL** (type-safe, IDE completion) |
| Formatter | Spotless + googleJavaFormat | **spring-java-format** (Spring-official) |
| Checkstyle | ✅ Present (10.25.0) | Present (10.17.0) + suppressions.xml |
| SpotBugs | ✅ Present (4.9.3) | Present (4.8.6) + exclude XML |
| ArchUnit | ✅ Present (1.4.0) | **6-rule set** (Layered + Entity isolation + DTO boundary + Transaction + Naming + multi-module prep) |
| springdoc-openapi | NOT FOUND | **Added** (2.5.0) — /swagger-ui.html + /api-docs |
| Commitlint (CI) | NOT FOUND | **`wagoid/commitlint-github-action@v6`** + `.commitlintrc.json` |
| Dockerfile (multi-stage) | NOT FOUND | **Multi-stage** (JDK 17 build → JRE 17 runtime, layered jar) |
| ECS task-definition.json | NOT FOUND | **`aws/task-definition.json`** template (Fargate CPU256/Mem512) |
| AppProperties record | NOT FOUND | **`examples/config/AppProperties.java`** — @ConfigurationProperties pattern |
| CI `fetch-depth: 0` | NOT SET | ✅ Set (commitlint requirement) |
