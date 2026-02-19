---
name: coco-fix-iterate
description: Iterative quality convergence loop. Reviews, scores, fixes, and re-scores code until target quality is reached. Use /coco-fix-iterate [--score N] [--max-iterations N] [focus].
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# COCO Fix Iterate

Autonomous iterative quality loop that reviews, scores, plans fixes, applies them, verifies, and re-scores — repeating until the code reaches a target quality score.

This skill combines the best of `/code-review` and `/code-fix` into a self-driving convergence loop.

## How it works

This skill is **agent-implemented** — the agent reads the steps below and executes them autonomously. There is no standalone bash script.

```
/coco-fix-iterate
/coco-fix-iterate --score 90
/coco-fix-iterate --max-iterations 5 security
```

## Input

- `$ARGUMENTS` may contain:
  - `--score N` — Target score threshold (default: 85)
  - `--max-iterations N` — Maximum iteration cycles (default: 10)
  - Remaining text = focus area (e.g., "security", "tests", "src/api/")

### Examples

```
/coco-fix-iterate                              # Full project, score >= 85, max 10 iterations
/coco-fix-iterate --score 90                   # Higher quality bar
/coco-fix-iterate --max-iterations 5 security  # Focus on security, max 5 rounds
/coco-fix-iterate src/api/                     # Focus on specific directory
```

## Parse Arguments

```bash
# Default values
TARGET_SCORE=85
MAX_ITERATIONS=10
FOCUS=""

# Parse from $ARGUMENTS
# --score N -> TARGET_SCORE=N
# --max-iterations N -> MAX_ITERATIONS=N
# remaining text -> FOCUS
```

## Algorithm

```
ITERATION = 0
PREVIOUS_SCORE = 0
SCORE_HISTORY = []

while ITERATION < MAX_ITERATIONS:
    ITERATION += 1

    # 1. REVIEW
    score, issues = review(FOCUS)
    SCORE_HISTORY.append(score)

    # 2. CHECK CONVERGENCE
    if score >= TARGET_SCORE and |score - PREVIOUS_SCORE| < 2:
        CONVERGED → STOP
    if is_oscillating(SCORE_HISTORY):
        OSCILLATING → STOP
    if is_diminishing(SCORE_HISTORY):
        DIMINISHING RETURNS → STOP

    # 3. PLAN FIXES (P0 first, then P1, then P2)
    plan = plan_fixes(issues)

    # 4. APPLY FIXES
    apply(plan)

    # 5. VERIFY (tests must pass)
    if not verify():
        revert_last_fix()
        continue

    PREVIOUS_SCORE = score

REPORT final results
```

## Phase 1: Initial Review (Iteration 1)

Perform a full `/code-review` following the same 12-dimension framework:

### 1.1 Run Automated Checks

```bash
# Auto-detect project type and run checks
if [ -f "pnpm-lock.yaml" ]; then
  pnpm typecheck 2>&1 || true
  pnpm lint 2>&1 || true
  pnpm test 2>&1 || true
elif [ -f "yarn.lock" ]; then
  yarn typecheck 2>&1 || true
  yarn lint 2>&1 || true
  yarn test 2>&1 || true
elif [ -f "package-lock.json" ]; then
  npm run typecheck 2>&1 || true
  npm run lint 2>&1 || true
  npm test 2>&1 || true
elif [ -f "Cargo.toml" ]; then
  cargo clippy 2>&1 || true
  cargo test 2>&1 || true
elif [ -f "pyproject.toml" ]; then
  ruff check . 2>&1 || true
  pytest 2>&1 || true
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  ./gradlew check 2>&1 || true
fi
```

### 1.2 Manual Code Analysis

Read and analyze code across the 12 dimensions (see `/code-review` for details):

| Dimension | Weight |
|---|---|
| Correctness | 15% |
| Completeness | 10% |
| Robustness | 10% |
| Readability | 10% |
| Maintainability | 10% |
| Complexity | 8% |
| Duplication | 7% |
| Test Coverage | 10% |
| Test Quality | 5% |
| Security | 8% |
| Documentation | 4% |
| Style | 3% |

### 1.3 Score and Classify

Calculate weighted score. Classify all issues by severity (P0/P1/P2/P3).

### 1.4 Display Iteration Header

```
╔══════════════════════════════════════╗
║  ITERATION 1 / 10                   ║
║  Score: XX/100 (Grade X)            ║
║  Target: 85  |  Issues: N           ║
║  P0: N  P1: N  P2: N  P3: N        ║
╚══════════════════════════════════════╝
```

## Phase 2: Convergence Check

After each scoring, check if we should stop:

### 2.1 Target Reached
```
IF score >= TARGET_SCORE AND |score - previous_score| < 2:
  → STOP (converged)
```

### 2.2 Excellent Quality
```
IF score >= 95:
  → STOP (target_reached — excellent quality)
```

### 2.3 Oscillating
```
IF last 4 scores alternate up/down with delta < 3:
  → STOP (oscillating — no further progress possible)
```

### 2.4 Diminishing Returns
```
IF last 3 improvements are all < 1 point:
  → STOP (diminishing_returns)
```

### 2.5 Stuck Below Minimum
```
IF iteration >= 5 AND score < TARGET_SCORE - 20 AND no improvement in 3 iterations:
  → STOP (stuck — needs manual intervention)
```

### 2.6 Max Iterations
```
IF iteration >= MAX_ITERATIONS:
  → STOP (max_iterations)
```

## Phase 3: Plan Fixes

Based on the review findings, create a targeted fix plan:

1. **Select issues to fix this iteration** — prioritize:
   - All P0 (Critical) issues — always fix these
   - P1 (High) issues — fix as many as feasible
   - P2 (Medium) — fix only if P0 and P1 are clear
   - Never fix P3 in the loop (cosmetic, not worth the churn risk)

2. **Estimate impact** — focus on fixes that will improve the score the most:
   - Fixing a failing test (Correctness +15%)
   - Adding missing error handling (Robustness +10%)
   - Adding tests for uncovered code (Test Coverage +10%)

3. **Limit scope per iteration** — max 5-7 fixes per cycle to keep changes reviewable

Present the plan briefly (not waiting for user confirmation — this is autonomous):

```
Iteration 2: Fixing 4 issues
  - P0: Fix SQL injection in src/api/users.ts:42
  - P1: Add error handling in src/service/auth.ts:88
  - P1: Fix failing test in test/api.test.ts:15
  - P2: Remove duplicated validation in src/utils/validate.ts:30
```

## Phase 4: Apply Fixes

Apply each fix following the `/code-fix` guidelines:

1. **Read** the file
2. **Fix** the specific issue (minimal change)
3. **Quick verify** — typecheck after each fix:
   ```bash
   pnpm typecheck 2>&1 || npm run typecheck 2>&1 || cargo check 2>&1 || true
   ```
4. **If the fix breaks something**, revert it and move to the next issue

### Fix Safety Rules

- **Never change more than needed** — fix the issue, not the neighborhood
- **If tests fail after a fix, revert** — a fix that breaks tests is not a fix
- **Track what was changed** — maintain a list of modified files and changes
- **Preserve git history** — do NOT commit during the loop (user decides when to commit)

## Phase 5: Verify

After all fixes for this iteration are applied:

```bash
# Run full check suite
if [ -f "pnpm-lock.yaml" ]; then
  pnpm check 2>&1 || pnpm test 2>&1
elif [ -f "yarn.lock" ]; then
  yarn test 2>&1
elif [ -f "package-lock.json" ]; then
  npm test 2>&1
elif [ -f "Cargo.toml" ]; then
  cargo test 2>&1
elif [ -f "pyproject.toml" ]; then
  pytest 2>&1
fi
```

- If **tests pass** → proceed to re-scoring (Phase 1 of next iteration)
- If **tests fail** → revert the last fix that likely caused the failure, re-run tests
- If **still failing** → revert all fixes from this iteration and re-score at previous state

## Phase 6: Re-Score and Loop

Go back to Phase 1 with the updated code. The review now focuses on:
- Verifying previous fixes actually resolved the issues
- Finding new issues exposed by the fixes
- Re-scoring all 12 dimensions

Display the iteration header and score progression:

```
╔══════════════════════════════════════╗
║  ITERATION 3 / 10                   ║
║  Score: 79/100 (Grade B) ↑ +7       ║
║  Target: 85  |  Issues: 8 (was 15)  ║
║  P0: 0  P1: 2  P2: 4  P3: 2        ║
║                                      ║
║  History: 65 → 72 → 79              ║
╚══════════════════════════════════════╝
```

## Final Report

When the loop stops (for any reason), present the final report:

```
## COCO Fix Iterate — Final Report

### Result
- **Status: CONVERGED** (or: MAX_ITERATIONS / OSCILLATING / DIMINISHING / STUCK)
- **Final Score: XX/100 (Grade X)**
- **Target: XX | Iterations: N/MAX**

### Score Progression

| Iter | Score | Delta | Issues | Fixes Applied |
|------|-------|-------|--------|---------------|
| 1    | 65    | —     | 15     | —             |
| 2    | 72    | +7    | 11     | 4             |
| 3    | 79    | +7    | 8      | 3             |
| 4    | 84    | +5    | 5      | 3             |
| 5    | 86    | +2    | 3      | 2             |

### Score Chart
  100 ┤
   90 ┤                          ●  target: 85
   80 ┤              ●     ●
   70 ┤        ●
   60 ┤  ●
      └────┬────┬────┬────┬────
           1    2    3    4    5

### Dimension Breakdown (Final)

| Dimension        | Start | Final | Change |
|------------------|-------|-------|--------|
| Correctness      | 60    | 95    | +35    |
| Security         | 40    | 90    | +50    |
| Test Coverage    | 50    | 85    | +35    |
| ...              | ...   | ...   | ...    |

### All Fixes Applied (N total)
- [x] P0: [file:line] Description
- [x] P1: [file:line] Description
- [x] P1: [file:line] Description
- ...

### Remaining Issues (N)
- P2: [file:line] Description
- P3: [file:line] Description

### Files Modified (N)
- path/to/file1.ts
- path/to/file2.ts

### Recommendations
- If score < target: "Run again with a higher --max-iterations or fix remaining P1 issues manually"
- If converged: "Code quality meets the target. Consider committing these changes."
```

## Important

- This skill runs **autonomously** — it does NOT pause for user confirmation between iterations
- It **does NOT commit** — all changes stay in the working tree for the user to review
- The default target score of **85** represents senior-level quality
- Use `--score 95` for production-critical code that needs excellent quality
- Use `--score 70` for prototypes or spikes where speed matters more
- If the score is stuck, the skill stops rather than making useless changes
- P3 (cosmetic) issues are **never fixed** in the loop to avoid unnecessary churn
- After completion, the user can run `/code-review` to independently verify the final score
