# CodeRabbit Prompt Guide for Language Templates

This guide defines how each language template must author its
`.coderabbit.yaml` `path_instructions` block so that CodeRabbit reviews
**architecture + logic + security + convention** violations — not formatting.

## Universal Rules
1. `ignore_formatting: true` is MANDATORY. Formatting is owned by the language's
   formatter (Prettier / spring-java-format / Ruff).
2. `review.auto_review: true` on all templates.
3. Every template must supply `path_instructions` with AT LEAST two entries:
   one for production code, one for tests.

## Content Checklist per Language
Each template's path_instructions MUST cover:
- [ ] Architecture violations (layer/module boundary breaks)
- [ ] Type safety (strict mode violations, `any`/`Any`/`Object` overuse)
- [ ] Performance anti-patterns specific to the ecosystem
- [ ] Security patterns (input validation, secrets, injection)
- [ ] Export/import convention (Barrel / package / `__init__.py`)
- [ ] Explicit "do NOT comment on formatting" clause

## Language-Specific Focus

### TypeScript / Next.js
- FSD boundary violations (feature → feature direct import)
- Missing `'use client'` directive
- React 19 `use()` misuse
- Server/Client component boundary

### Java / Spring Boot
- `@Transactional` misplacement
- JPA N+1 without `JOIN FETCH` / `@EntityGraph`
- DTO/Entity leak
- ArchUnit layered rule violations

### Python (FastAPI / Data-engine)
- Ruff `PERF`/`PD` rule violations
- `basedpyright strict` type errors
- `syrupy` snapshot misuse
- `inplace=True` on pandas DataFrames

## Commit Convention Enforcement — NOT CodeRabbit's Job
CodeRabbit is a **code review** tool, not a commit-lint tool. Commit message
convention enforcement lives in separate layers:

| Layer | Tool | Location |
|---|---|---|
| Local (pre-commit) | Husky + commitlint (TS) | `.husky/commit-msg` |
| CI (pull request) | `wagoid/commitlint-github-action@v6` | `.github/workflows/ci.yml` first step |
| Pre-push safety | Git Safety Gate inline bash | SETUP.md Phase 8.1 |

Do NOT add commit-convention rules to `.coderabbit.yaml`. Keep CodeRabbit
focused on logic, architecture, and security.

## Prompt Language
Prompts inside `path_instructions` SHOULD be in English for consistency
(CodeRabbit's internal LLM prefers English). Tone: senior engineer, objective.
