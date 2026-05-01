/**
 * Order module — DDD/TDD pilot for Phase E0.
 *
 * Marked as @ApplicationModule explicitly so Spring Modulith does not
 * detect core/support as separate modules (which would cause spurious
 * cross-module violations). With detection-strategy=explicitly-annotated
 * in application.yml, only this package is treated as a module.
 */
@org.springframework.modulith.ApplicationModule(displayName = "Order")
package com.example.template.order;
