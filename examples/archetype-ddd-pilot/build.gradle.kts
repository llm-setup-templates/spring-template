plugins {
    java
    id("org.springframework.boot") version "3.5.0"
    id("io.spring.dependency-management") version "1.1.7"
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

dependencyManagement {
    imports {
        mavenBom("org.springframework.modulith:spring-modulith-bom:1.4.0")
    }
}

dependencies {
    // Spring Boot starters (initializr-seed parity)
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-web")

    // jMolecules DDD annotations (Q3=B). Note: @DomainEvent is in jmolecules-events, NOT jmolecules-ddd.
    implementation("org.jmolecules:jmolecules-ddd:1.9.0")
    implementation("org.jmolecules:jmolecules-events:1.9.0")

    // Spring Modulith core (BOM-managed version 1.4.0 -> Spring Boot 3.5 compatible)
    implementation("org.springframework.modulith:spring-modulith-starter-core")

    // PostgreSQL driver (runtime)
    runtimeOnly("org.postgresql:postgresql")

    // Test
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testImplementation("org.springframework.modulith:spring-modulith-starter-test")
    testImplementation("org.springframework.boot:spring-boot-testcontainers")
    testImplementation("org.testcontainers:postgresql")
    testImplementation("org.testcontainers:junit-jupiter")
    // Spring Boot BOM does not manage REST Assured -- explicit version required.
    testImplementation("io.rest-assured:rest-assured:5.5.0")
    // ArchUnit for DDD architecture tests (R13-R16)
    testImplementation("com.tngtech.archunit:archunit-junit5:1.3.0")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
