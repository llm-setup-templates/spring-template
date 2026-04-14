package com.example.architecture;

// TODO: replace com.example with {{BASE_PACKAGE}}

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.library.Architectures;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * ArchUnit architecture enforcement tests.
 *
 * <p>These tests run as part of the normal test suite (./gradlew test).
 * All 6 rules must remain enabled - see .coderabbit.yaml for PR-level checks.
 *
 * <p>Multi-module scaling path: when splitting to multi-module (team-dodn pattern),
 * package names map directly: com.example.core, com.example.clients,
 * com.example.storage, com.example.support. Rule 6 enforces this from day one.
 *
 * <p>Empty-scaffold compatibility: layeredArchitecture uses withOptionalLayers(true)
 * and src/test/resources/archunit.properties sets archRule.failOnEmptyShould=false,
 * so the rules pass on a day-0 skeleton before any controllers/services exist.
 * Remove those once real classes land if you prefer strict enforcement.
 */
@AnalyzeClasses(packages = "com.example", importOptions = {ImportOption.DoNotIncludeTests.class})
public class ArchitectureTest {

    // Rule 1: Layered Architecture
    // Controller -> Service -> Repository (unidirectional only)
    @ArchTest
    static final ArchRule layeredArchitecture =
        Architectures.layeredArchitecture()
            .consideringAllDependencies()
            .withOptionalLayers(true)
            .layer("Controller").definedBy("..controller..")
            .layer("Service").definedBy("..service..")
            .layer("Repository").definedBy("..repository..")
            .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
            .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
            .whereLayer("Repository").mayOnlyBeAccessedByLayers("Service");

    // Rule 2: Entity Isolation
    // Controllers must not access domain entities directly - use DTOs
    @ArchTest
    static final ArchRule entityIsolation = noClasses()
        .that().resideInAPackage("..controller..")
        .should().accessClassesThat().resideInAPackage("..domain..")
        .as("Controllers must not access domain entities directly - use DTOs");

    // Rule 3: DTO Boundary
    // DTOs must not carry JPA annotations
    @ArchTest
    static final ArchRule dtoBoundary = noClasses()
        .that().resideInAPackage("..dto..")
        .should().beAnnotatedWith("jakarta.persistence.Entity")
        .orShould().beAnnotatedWith("jakarta.persistence.Table")
        .as("DTOs must not carry JPA annotations");

    // Rule 4: Transaction Placement
    // @Transactional must only appear in service layer
    @ArchTest
    static final ArchRule transactionPlacement = methods()
        .that().areAnnotatedWith(org.springframework.transaction.annotation.Transactional.class)
        .should().beDeclaredInClassesThat().resideInAPackage("..service..")
        .as("@Transactional must only appear in service layer");

    // Rule 5a: Controller Naming
    @ArchTest
    static final ArchRule controllerNaming = classes()
        .that().resideInAPackage("..controller..")
        .and().areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
        .should().haveSimpleNameEndingWith("Controller");

    // Rule 5b: Service Naming
    @ArchTest
    static final ArchRule serviceNaming = classes()
        .that().resideInAPackage("..service..")
        .and().areAnnotatedWith(org.springframework.stereotype.Service.class)
        .should().haveSimpleNameEndingWith("Service")
        .orShould().haveSimpleNameEndingWith("UseCase");

    // Rule 5c: Repository Naming
    // Note: ArchRuleDefinition has no interfaces() static method - use
    // classes().that()...and().areInterfaces() instead.
    @ArchTest
    static final ArchRule repositoryNaming = classes()
        .that().resideInAPackage("..repository..")
        .and().areInterfaces()
        .should().haveSimpleNameEndingWith("Repository");

    // Rule 6: Multi-Module Package Boundary Preparation
    // Enforces that all classes live within com.example package hierarchy.
    // When scaling to multi-module (team-dodn pattern), packages map to:
    //   com.example.core, com.example.clients, com.example.storage, com.example.support
    // Migration = Gradle settings.gradle.kts include() change + move packages.
    @ArchTest
    static final ArchRule packageBoundaries = classes()
        .should().resideInAPackage("com.example..")
        .as("All classes must reside within com.example package hierarchy "
            + "(multi-module split preparation)");

}
