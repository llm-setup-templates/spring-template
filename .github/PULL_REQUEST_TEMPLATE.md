## Summary

<!-- 1–3 sentences. What changes and why. -->

## Related documents

<!-- Link every applicable document. Delete rows that don't apply. -->

- [ ] FR: `docs/requirements/FR-XX.md` — <!-- closes #... -->
- [ ] ADR: `docs/architecture/decisions/ADR-NNN-<slug>.md` — <!-- Accepted via this PR -->
- [ ] RFC: `docs/architecture/decisions/RFC-NNN-<slug>.md` — <!-- still Proposed, not in scope for merge -->
- [ ] Report: `docs/reports/<type>-YYYY-MM-DD-<slug>.md` — <!-- spike / benchmark / api-analysis / paar -->
- [ ] Briefing: `docs/briefings/YYYY-MM-DD-<slug>/` — <!-- event archive -->

## RTM discipline

- [ ] If this PR implements or changes an FR, `docs/requirements/RTM.md`
      is updated in this PR (new row or cell edits) — **mandatory when
      the FR row exists**.

## Architecture / layer checks

<!-- Check everything that applies. Unchecked items with a comment explaining why = acceptable. -->

- [ ] Layer direction respected (`api → domain → repository` via interfaces)
      — no controller → repository shortcut
- [ ] `@Transactional` placed on the service layer (read-only on queries,
      default on writes), never on controllers or repositories
- [ ] Entities (`@Entity`) are NOT returned from `@RestController` — DTOs only
- [ ] No JPA N+1: any `@OneToMany` / `@ManyToOne` fetched eagerly has a
      justification, or `@EntityGraph` / `JOIN FETCH` is used where needed
- [ ] ArchUnit tests pass (`./gradlew test` includes `ArchitectureTest`)
- [ ] Bean Validation annotations on DTO request fields (`@NotNull`,
      `@Email`, `@Size`, etc.) — not post-hoc `if (x == null)` checks
- [ ] No `System.out.println` / `System.err.println` — SLF4J `Logger` only

## Data-flow Balancing Rule (only if DFD changed)

- [ ] No Black Hole (a process with input but no output)
- [ ] No Miracle (a process with output but no input)
- [ ] No Gray Hole (a process whose outputs cannot be derived from its
      inputs — e.g. returns PII that wasn't fetched)
- [ ] Terminology is consistent between parent and child levels

## Verification

- [ ] `./gradlew checkFormat checkstyleMain checkstyleTest spotbugsMain test build bootJar`
      passes locally
- [ ] Tests updated in the same commit as the code change
      (see `.claude/rules/test-modification.md`)
- [ ] If adding / changing a JPA entity, a Testcontainers integration
      test exercises the schema (not only H2 in-memory)

## Business impact (only for large or risky changes)

<!-- Delete this section for routine changes. Required for ADR-level PRs. -->

**Cost**: <!-- infrastructure, managed DB tier, engineer time -->
**Risk**: <!-- what can go wrong, what's the blast radius -->
**Velocity impact**: <!-- what does this enable / block for the next sprint -->
