---
name: claude-md-reviewer
description: >
  Reviews, creates, and optimizes CLAUDE.md and .claude/ folder structures
  against Anthropic's official best practices. Produces a scored report
  with concrete improvement suggestions.
user_invocable: true
---

# CLAUDE.md Reviewer

Invoked when the user runs `/claude-md-reviewer` or
`/claude-md-reviewer [mode]`.

**Usage:**
- `/claude-md-reviewer` — auto-detect the current project's CLAUDE.md and review
- `/claude-md-reviewer review` — Mode A (review)
- `/claude-md-reviewer create` — Mode B (create)
- `/claude-md-reviewer structure` — Mode C (structure optimization)

---

## Execution Procedure

### Step 1: Mode Detection

If no argument is provided, check whether `.claude/` folder and CLAUDE.md exist:
- CLAUDE.md exists → Mode A (review)
- CLAUDE.md missing → Mode B (create)
- `.claude/rules/` has 5+ files → also run Mode C in parallel

### Step 2: Target File Collection

Scan all of the following paths and collect the list of existing files:

```
./CLAUDE.md
./.claude/CLAUDE.md
./CLAUDE.local.md
./.claude/rules/**/*.md
./.claude/skills/**/SKILL.md
./.claude/settings.json
./.claude/settings.local.json
*/CLAUDE.md              (subdirectories)
```

### Step 3: Execute Mode → Step 4: Output Results

---

## Mode A: Review

Score the collected CLAUDE.md against the following **7 criteria**.

### Scoring Criteria

**1. Length (Length)**
- ✅ 200 lines or fewer
- ⚠️ 200–300 lines (separation recommended)
- ❌ Over 300 lines (separation mandatory)
- Rationale: "Files over 200 lines consume more context and may reduce adherence"

**2. Specificity (Specificity)**
- Is each rule specific enough for the AI to self-verify?
- ❌ "Write clean code"
- ✅ "Functions must be ≤ 30 lines with ≤ 3 parameters"
- Test: "Can Claude automatically verify whether this rule was followed?"

**3. Verification Loop (Verification Loop)**
- Are build, test, and lint commands included?
- Is there a self-verification instruction like "after any code change, always run X"?

**4. Modularization (Modularization)**
- Is there a large single-file CLAUDE.md that should be split? → suggest `.claude/rules/`
- Is `@path` import syntax being used?
- Does the scale warrant per-subdirectory CLAUDE.md?

**5. Universality (Universality)**
- Does CLAUDE.md contain only content applicable to every task?
- Are there module-specific rules mixed in?
- Rationale: "Since CLAUDE.md goes into every single session, ensure contents are universally applicable"

**6. WHAT-WHY-HOW Completeness**
- **WHAT**: Is the tech stack and project structure described?
- **WHY**: Is the project purpose and each module's role explained?
- **HOW**: Are build / test / deploy instructions present?

**7. Domain Terms (Domain Terms)**
- Are project-specific terms defined?
- Are potentially confusing concepts clearly distinguished?

### Output Format

```markdown
# CLAUDE.md Review Results

## Summary
[One-line summary]

## Scorecard
| Criterion | Rating | Notes |
|-----------|--------|-------|
| Length | ✅/⚠️/❌ | ... |
| Specificity | ✅/⚠️/❌ | ... |
| Verification Loop | ✅/⚠️/❌ | ... |
| Modularization | ✅/⚠️/❌ | ... |
| Universality | ✅/⚠️/❌ | ... |
| WHAT-WHY-HOW | ✅/⚠️/❌ | ... |
| Domain Terms | ✅/⚠️/❌ | ... |

## Top 3 Improvements
1. [Most urgent issue + concrete fix]
2. ...
3. ...

## Revised CLAUDE.md Draft
[Full revised text or key changed sections]

## .claude/ Folder Structure Suggestion (if applicable)
[rules separation, skills organization, etc.]
```

---

## Mode B: Create

Run when no CLAUDE.md exists. Analyze the codebase and generate CLAUDE.md + rules/ files.

See full procedure in the original SKILL.md from _skeleton/.claude/skills/claude-md-reviewer/.

---

## Mode C: Structure Optimization

Analyze the full `.claude/` folder + `.plans/` + `context/` and suggest the optimal structure.

See full procedure in the original SKILL.md from _skeleton/.claude/skills/claude-md-reviewer/.
