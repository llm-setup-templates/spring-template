package {{BASE_PACKAGE}}.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Type-safe configuration properties bound from application.yml prefix "app".
 *
 * <p>Usage in main application class:
 * <pre>
 * {@literal @}SpringBootApplication
 * {@literal @}EnableConfigurationProperties(AppProperties.class)
 * public class Application {
 *     public static void main(String[] args) {
 *         SpringApplication.run(Application.class, args);
 *     }
 * }
 * </pre>
 *
 * <p>Example application.yml:
 * <pre>
 * app:
 *   name: my-service
 *   max-items: 100
 * </pre>
 *
 * <p>Preferred over {@literal @}Value for type safety, IDE completion, and testability.
 */
@ConfigurationProperties(prefix = "app")
public record AppProperties(String name, int maxItems) {
}
