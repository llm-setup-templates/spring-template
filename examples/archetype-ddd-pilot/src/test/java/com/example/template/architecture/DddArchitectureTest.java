package com.example.template.architecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * DDD architecture rules (R13-R16) for Phase E0 pilot.
 *
 * D11: scoped to com.example.template.order to isolate from web-mvc archetype's ArchitectureTest.
 */
@AnalyzeClasses(packages = "com.example.template.order",
    importOptions = {ImportOption.DoNotIncludeTests.class})
public class DddArchitectureTest {

    // R13: @AggregateRoot must reside in ..domain.. package
    @ArchTest
    static final ArchRule aggregateRootInDomain = classes()
        .that().areAnnotatedWith(org.jmolecules.ddd.annotation.AggregateRoot.class)
        .should().resideInAPackage("..domain..")
        .as("R13: @AggregateRoot must reside in ..domain.. package");

    // R14: @DomainEvent must reside in ..domain.. package (jmolecules-events)
    @ArchTest
    static final ArchRule domainEventInDomain = classes()
        .that().areAnnotatedWith(org.jmolecules.event.annotation.DomainEvent.class)
        .should().resideInAPackage("..domain..")
        .as("R14: @DomainEvent must reside in ..domain.. package");

    // R15: jMolecules @Repository interface must reside in ..domain.. (impl in ..infrastructure..)
    @ArchTest
    static final ArchRule repositoryInterfaceInDomain = classes()
        .that().areAnnotatedWith(org.jmolecules.ddd.annotation.Repository.class)
        .and().areInterfaces()
        .should().resideInAPackage("..domain..")
        .as("R15: jMolecules @Repository interface must reside in ..domain..");

    // R16: ..domain.. must not depend on ..infrastructure.. (dependency inversion)
    @ArchTest
    static final ArchRule domainNotDependOnInfrastructure = noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat().resideInAPackage("..infrastructure..")
        .as("R16: domain layer must not depend on infrastructure (dependency inversion)");
}
