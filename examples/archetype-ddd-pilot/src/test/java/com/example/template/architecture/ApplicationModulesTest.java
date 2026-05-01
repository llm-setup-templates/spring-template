package com.example.template.architecture;

import com.example.template.TemplateApplication;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

import static org.assertj.core.api.Assertions.assertThat;

class ApplicationModulesTest {

    @Test
    void verifiesModuleStructure() {
        // R4 R4-H1/CX-30: ApplicationModules.of(Class).verify() -- void return, throws Violations on failure.
        ApplicationModules modules = ApplicationModules.of(TemplateApplication.class);
        try {
            modules.verify();
        } catch (org.springframework.modulith.core.Violations v) {
            // Surface violation details to test output (debugging aid for CI).
            System.err.println("=== Spring Modulith Violations ===");
            System.err.println(v.getMessage());
            throw v;
        }
    }

    @Test
    void detectsOrderModule() {
        ApplicationModules modules = ApplicationModules.of(TemplateApplication.class);
        // R4 R4-H1: getModuleByName direct (no detected() method exists in Modulith API)
        assertThat(modules.getModuleByName("order"))
            .as("'order' module should be discovered as a Spring Modulith module")
            .isPresent();
    }
}
