# Test Modification Scenarios — Spring Boot / JUnit 5

Three concrete scenarios demonstrating `.claude/rules/test-modification.md` in action.
Each scenario starts from a working Spring Boot project with passing tests.

---

## Scenario A: Add GET /api/items endpoint

**Code change type**: REST endpoint added
**Affected layers**: unit + integration + ArchUnit (auto)

### Code changes

```java
// src/main/java/com/example/item/ItemController.java (new)
@RestController
@RequestMapping("/api/items")
@RequiredArgsConstructor
public class ItemController {
    private final ItemService itemService;

    @GetMapping
    public List<ItemResponse> getAll() {
        return itemService.findAll();
    }
}
```

```java
// src/main/java/com/example/item/ItemService.java (new)
@Service
@RequiredArgsConstructor
public class ItemService {
    private final ItemRepository itemRepository;

    public List<ItemResponse> findAll() {
        return itemRepository.findAll().stream()
            .map(ItemResponse::from)
            .toList();
    }
}
```

### Required test changes

**1. Service unit test** — `src/test/java/com/example/item/ItemServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class ItemServiceTest {
    @Mock private ItemRepository itemRepository;
    @InjectMocks private ItemService itemService;

    @Test
    void findAll_returnsAllItems() {
        // Arrange
        when(itemRepository.findAll()).thenReturn(List.of(
            new Item(1L, "Widget", BigDecimal.valueOf(9.99))
        ));
        // Act
        var result = itemService.findAll();
        // Assert
        assertThat(result).hasSize(1);
        assertThat(result.get(0).name()).isEqualTo("Widget");
    }
}
```

**2. Controller integration test** — `src/test/java/com/example/item/ItemControllerTest.java`

```java
@WebMvcTest(ItemController.class)
class ItemControllerTest {
    @Autowired private MockMvc mockMvc;
    @MockBean private ItemService itemService;

    @Test
    void getAll_returns200() throws Exception {
        when(itemService.findAll()).thenReturn(List.of(
            new ItemResponse(1L, "Widget", BigDecimal.valueOf(9.99))
        ));

        mockMvc.perform(get("/api/items"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].name").value("Widget"));
    }
}
```

**ArchUnit**: No changes needed — ArchUnit auto-validates that `ItemController` only depends on `ItemService` (not `ItemRepository` directly).

---

## Scenario B: Add updatedAt field to existing entity

**Code change type**: JPA entity / DB schema changed
**Affected layers**: unit (DTO mapping) + integration (DB fixtures)

### Code change

```java
// Item.java — add field
@Column(name = "updated_at")
private LocalDateTime updatedAt;
```

### What happens

1. `./gradlew test` → existing tests may fail if they assert on entity field count or DTO mapping
2. Integration tests using H2/Testcontainers need schema update

### Correct approach

- Update `ItemResponse` DTO to include `updatedAt` (or explicitly exclude it)
- Update test fixtures to include the new field
- If using Flyway/Liquibase: add migration script + migration test
- Do NOT modify ArchUnit rules

### What NOT to do

- Do NOT add `@Disabled` to failing tests
- Do NOT return the JPA entity directly from the controller (ArchUnit will catch this)

---

## Scenario C: Extract service method (refactoring)

**Code change type**: Refactoring (behavior unchanged)
**Affected layers**: none

### Code change

```java
// Before: ItemService.findAll() has inline mapping logic
// After: Extract to ItemMapper.toResponse()
@Component
public class ItemMapper {
    public ItemResponse toResponse(Item item) {
        return new ItemResponse(item.getId(), item.getName(), item.getPrice());
    }
}
```

### Required test changes

**None.** All existing tests must pass without modification.

- `./gradlew test` → all green → refactoring is correct
- If any test fails → the refactoring changed behavior → **fix the code, not the tests**
- ArchUnit still passes (new `@Component` follows layering rules)

### Common mistakes

- Adding unit tests for `ItemMapper` — unnecessary if `ItemServiceTest` already covers the mapping behavior through `findAll()`
- Changing mock setup in existing tests to match new internal structure — tests should verify behavior, not implementation
