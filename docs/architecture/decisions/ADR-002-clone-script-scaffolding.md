# ADR-002: Clone + Script Scaffolding over gh --template (Spring)

Status: Accepted (2026-04-25)
Supersedes: Implicit Phase 0/0.5/1 flow in SETUP.md (pre-Phase-13b, removed)
Related: ADR-001 (JaCoCo coverage threshold — unchanged)

## Context

Through Phase 12, `SETUP.md` began every session with a `gh repo create --source=.`
call, making GitHub CLI a **hard dependency for Phase 0**. Phase 0.5 then cloned
`/tmp/ref-spring` with `gh repo clone`, Phase 1 fetched the Initializr starter.zip
via `curl`, and Phase 8 pushed with `gh run watch`. Five distinct external calls,
the earliest at the very first step.

This was the same blocker the Python template solved in Phase 13 (PR #21/#22/#23,
merged 2026-04-23~24). The trigger was Codex's e2e23 dry run, which spent 2m 26s
attempting to locate Windows `gh.exe` from inside its Linux sandbox before
hitting quoting+IO encoding failures and **never reaching Phase 1**.

For Spring there is an additional twist: Phase 1 itself depended on
`curl https://start.spring.io/starter.zip` — a network call to a third-party
service. This added a second external dependency (Initializr availability)
beyond `gh`, breaking even environments that have `gh` but no outbound HTTPS
to start.spring.io (corporate proxies, air-gapped CI).

The preceding Phase 11/12 fixes tightened individual steps but kept the
coupling between "obtain template files" + "fetch Initializr seed" + "connect
to GitHub" intact.

## Decision

Separate "obtain template files" from "fetch Initializr seed" from "connect to GitHub":

1. **Template acquisition**: `git clone https://github.com/.../spring-template`.
   Requires only `git` (already present in every environment that can edit files,
   including Codex's sandbox).
2. **Initializr seed**: pre-baked at `examples/initializr-seed/` inside the
   template repo. Snapshot of `start.spring.io/starter.zip` output for
   Spring Boot 3.5.0 + Java 17 + web/data-jpa/validation/actuator. ~50KB.
   Refreshed on the template side via dependabot or explicit PR; derived
   repos do not call start.spring.io.
3. **Customization**: `bash ./scaffold.sh --project-name <hyphen-case> --base-package <dotted>`.
   Requires only `bash` ≥ 4.0. No network calls, no `gh`, no `curl`. 8-stage
   pipeline (Stage B is no-op for single-archetype Spring).
4. **GitHub connection (optional)**: `gh repo create` + `git push`. Moved to a
   separate `Publish to GitHub` section in SETUP.md § 4. Users who publish to
   private GitLab, self-hosted Gitea, or keep the repo local can skip this
   entire section.

scaffold.sh is single-use (detects `validate.sh` presence as freshness marker)
and self-deletes on success (Linux/macOS; Windows Git Bash prints a warning
and asks for manual deletion due to file locks on the running script).

## Alternatives considered

### A. `gh repo create --template llm-setup-templates/spring-template` (rejected)

Server-side templating via GitHub API. Clone-less, but:

- Still requires `gh` at step 1 → does not solve the Codex sandbox blocker.
- Still requires a second `curl start.spring.io` call → does not solve the
  Initializr offline blocker.
- Auto-creates an "Initial commit" message that violates the Conventional
  Commits gate in our own Phase 8 (empirically confirmed in Phase 06 notes).
- No access to substitute placeholders before first commit (user must
  rewrite history, which breaks the "one clean initial commit" contract).

### B. scaffold.sh + curl start.spring.io (rejected — Spring-specific)

Always fetch the latest Initializr snapshot at scaffold time. Pros: no version
staleness, smaller repo (no baked seed). Cons that overwhelm:

- Adds a network dependency on `start.spring.io` to scaffold.sh — a violation
  of ADR-002's "single-dependency scaffolding" principle (`bash` only).
- Codex's sandbox + air-gapped CI runners + GitLab mirrors with no egress to
  start.spring.io: scaffold.sh fails. Same class of blocker as `gh`, just
  shifted one layer.
- Network failure mid-scaffold leaves a partial state — harder to recover
  than a baked seed which is deterministic.
- Initializr API surface changes (new param names, deprecated bootVersion
  ranges) silently break future scaffold runs without any change to the
  template repo.

### C. degit (tarball download) (rejected)

`npx degit user/repo target-dir` downloads the template tarball without `.git`.
Clean, no git reinit step needed. But:

- Adds `npm` (Node.js) as a prerequisite — heavier than `git` for Java users
  who may not have Node installed.
- Still requires a separate Initializr fetch.
- Loses the ability to `git pull` future template updates into the derived
  repo (users who want that have to re-clone anyway, so this is a shallow
  benefit — but the added dependency is not).

### D. Keep current Phase 0/0.5/1 flow + add 7th Fix (rejected)

The "add yet another troubleshooting row" path. Rejected because:

- Phase 11/12 hardenings were already accumulating environment-specific
  workarounds (Foojay proxy, gradlew exec bit, CRLF line endings, CI
  no-run recovery, validate.yml template-only confusion). Adding a 7th
  doesn't stop the 8th.
- The underlying coupling (file acquisition ⊗ Initializr fetch ⊗ GitHub
  connection) is the root cause; troubleshooting entries only paper over
  symptoms.

## Consequences

### Positive

- **Single-dependency scaffolding**: `git` + `bash` is enough. Any environment
  that can `git clone` over HTTPS can scaffold, including Codex sandboxes,
  air-gapped CI runners with git proxies, or GitLab/Gitea mirrors.
- **Executable documentation**: scaffold.sh IS the scaffolding logic.
  SETUP.md shrinks from 686 lines to ~200 lines and documents "why / when /
  how to call" rather than "paste these 40 bash commands in order".
- **CI regression coverage**: scaffold.sh's behavior is now testable in
  `.github/workflows/validate.yml` via `test/scaffold-e2e.sh` (5-cell
  doc-modules matrix). Bugs in scaffolding are caught before they reach users.
- **Decoupled gh + Initializr**: publishing to GitHub is optional, and
  Initializr availability is irrelevant at scaffold time.
- **gradlew exec bit baked in**: the Initializr seed is committed to the
  template repo with `git update-index --chmod=+x` once, so derived repos
  inherit `100755` mode regardless of the user's filesystem semantics
  (Windows NTFS doesn't track exec bits natively; git's index is the
  authoritative source).

### Negative

- **scaffold.sh is a new, load-bearing file**: bugs here break all users.
  Mitigated by scaffold-e2e CI matrix + `--dry-run` flag + single-use
  freshness check + 3-condition Bash interpreter guard.
- **Single-use constraint surprises users**: re-running scaffold.sh errors
  out with "validate.sh not found". This is intentional (idempotent sed
  substitutions are fragile) but the error message must be clear. We
  instruct users to re-clone rather than retry.
- **Windows self-delete caveat**: scaffold.sh can't delete itself on
  Windows Git Bash (file lock). We warn and ask for manual cleanup. This
  is the cleanest outcome available without invoking an out-of-process
  helper.
- **Spring Boot version staleness in seed**: the baked Initializr output is
  a snapshot of one specific Spring Boot version (3.5.0 at template
  v1.1.0). When start.spring.io's compatibility window moves and 3.5.0
  becomes outdated, derived repos using the seed will lag. Mitigated by:
  (a) scaffold-e2e CI weekly schedule that catches build breaks; (b)
  Troubleshooting row "Re-fetch from start.spring.io if too stale";
  (c) Dependabot tracking transitive deps in the seed pyproject equivalent.
- **Application class name cosmetic**: derived repos inherit
  `TemplateApplication.java` from the seed (Initializr generated it from
  artifactId=template). After Stage D's package directory rename, the class
  ends up at e.g. `com.acme.foo.TemplateApplication` — functional but
  ugly. Documented in RATIONALE.md and SETUP.md Troubleshooting; users do
  IDE-rename for cosmetic correctness.
- **Phase 0.5 `/tmp/ref-spring` concept deleted**: pre-Phase-13b SETUP.md
  used a reference clone to copy template files. In the clone+script
  architecture, the cloned directory IS the reference — no separate copy
  needed. Users relying on that pattern (e.g., external docs) get a
  redirect hint in SETUP.md § 4.

## Implementation trail

- Plan: `.plans/llm-setup/13b-spring-clone-script-architecture/PLAN.md` (rev.4)
- Discussion: `.plans/llm-setup/13b-spring-clone-script-architecture/DISCUSS.md`
- Plan-review-deep --with-codex (3 rounds, Critical 0 convergence):
  Round 1 Reality Lens, Round 2 Runtime Contract Lens, Round 3 Completeness Lens
- Phase 13 Python lineage: ADR-002 (ref-python), PR #21/#22/#23
  (`5e3a24a`/`5a16bf3`/`18c9fa6`)
- Direct driver: same as Phase 13 Python (Codex e2e23 sandbox blocker), plus
  Spring-specific Initializr offline requirement
