# Git Workflow Rules

## Branch Strategy
- `main` is protected — never commit directly.
- Feature branches: `feat/<N>-<short-name>`
- Fix branches: `fix/<short-name>`
- Refactor: `refactor/<short-name>`
- Docs: `docs/<short-name>`
- All branches base on `main` unless stated otherwise.

## Commit Convention — Conventional Commits 1.0
Pattern: `<type>(<scope>): <description>`

Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`

Scope MUST be lowercase kebab-case. Description MUST start lowercase.

## One Task = One Commit
Each atomic task is one commit. No "WIP" or "misc" commits.

## No Force Push on Main
Force pushing to `main` is prohibited under any circumstance.
Use `git reset --soft HEAD~N` locally before the first push if commits
need rewriting.

## Pre-Push Gate (MANDATORY)
Before `git push` on any branch, verify all three:
- Current branch is not `main`
- Last 10 commit messages match the Conventional Commits regex
- No uncommitted changes in working tree

The CI commitlint job enforces the Conventional Commits rule; the branch
and clean-tree checks are the agent's responsibility before pushing.
