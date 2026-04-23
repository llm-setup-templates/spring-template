# Stage 1: Build
# Uses JDK 17 Alpine for compiling and packaging the Spring Boot application.
FROM eclipse-temurin:25-jdk-alpine AS builder
WORKDIR /workspace/app

# Gradle wrapper copied first (layer cache optimization — changes rarely)
COPY gradlew .
COPY gradle gradle
RUN chmod +x gradlew

# Copy build files and download dependencies before copying source.
# This layer is cached as long as build files don't change.
COPY build.gradle.kts settings.gradle.kts ./
COPY checkstyle checkstyle
COPY spotbugs spotbugs
RUN ./gradlew dependencies --no-daemon -q

# Copy source and build bootJar
COPY src src
RUN ./gradlew bootJar --no-daemon -q

# Extract layered jar for optimized Docker layer caching in Stage 2.
# Layer order (low-to-high change frequency):
#   dependencies → spring-boot-loader → snapshot-dependencies → application
RUN mkdir -p build/extracted && \
    java -Djarmode=layertools \
         -jar build/libs/*.jar extract \
         --destination build/extracted

# Stage 2: Runtime
# Uses JRE 17 Alpine (smaller image — no compiler toolchain).
FROM eclipse-temurin:25-jre-alpine AS runtime
WORKDIR /app

# Copy extracted layers in cache-friendly order
COPY --from=builder /workspace/app/build/extracted/dependencies/ ./
COPY --from=builder /workspace/app/build/extracted/spring-boot-loader/ ./
COPY --from=builder /workspace/app/build/extracted/snapshot-dependencies/ ./
COPY --from=builder /workspace/app/build/extracted/application/ ./

# Run as non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080

# Spring Boot 3.2+ launcher class path
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
