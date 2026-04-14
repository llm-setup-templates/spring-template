plugins {
    // Auto-provisions the JDK declared in build.gradle.kts toolchain block.
    // Team members with any installed JDK (or none) get the correct version
    // downloaded to ~/.gradle/jdks/ on first build. Keeps the template
    // independent of host JDK state.
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

rootProject.name = "{{PROJECT_NAME}}"
