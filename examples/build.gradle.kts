plugins {
    java
    id("org.springframework.boot") version "3.5.0"
    id("io.spring.dependency-management") version "1.1.7"
    id("checkstyle")
    id("com.github.spotbugs") version "6.0.26"
    id("io.spring.javaformat") version "0.0.47"
}

group = "com.example"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.5.0")
    runtimeOnly("org.postgresql:postgresql")
    testRuntimeOnly("com.h2database:h2")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("com.tngtech.archunit:archunit-junit5:1.4.0")
    testImplementation("org.springframework.boot:spring-boot-testcontainers")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

checkstyle {
    toolVersion = "10.17.0"
    configFile = file("checkstyle/checkstyle.xml")
    // Required so ${config_loc} in checkstyle.xml resolves to ./checkstyle/
    // instead of Gradle's default config/checkstyle/ — otherwise the
    // SuppressionFilter reference to suppressions.xml fails to load.
    configDirectory.set(file("checkstyle"))
    isIgnoreFailures = false
}

spotbugs {
    excludeFilter.set(file("spotbugs/spotbugs-exclude.xml"))
    ignoreFailures.set(false)
    toolVersion.set("4.8.6")
}

tasks.withType<com.github.spotbugs.snom.SpotBugsTask> {
    reports.create("html") { enabled = true }
    reports.create("xml") { enabled = false }
}
