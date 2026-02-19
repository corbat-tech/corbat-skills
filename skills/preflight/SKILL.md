---
name: preflight
description: Run all validation checks without releasing. Use before /release to verify everything is ready.
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
---

# Preflight Checks

Run all validations to confirm the project is ready for release. This does NOT create commits, PRs, tags, or publish anything.

## How it works

This skill is **agent-implemented** — the agent reads the steps below and executes them autonomously. There is no standalone bash script.

```
/preflight
```

## Step 1: Environment checks

```bash
git branch --show-current
git status --porcelain
gh auth status
```

Report:
- Current branch name
- Whether working tree is clean
- Whether gh is authenticated

## Step 2: Version analysis

```bash
# Current version (try package.json, Cargo.toml, pyproject.toml, build.gradle)
node -e "console.log(require('./package.json').version)" 2>/dev/null || echo "no package.json"

# Last tag
git describe --tags --abbrev=0 2>/dev/null || echo "no tags"

# Commits since last tag
git log $(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~50")..HEAD --oneline --no-decorate
```

Analyze commits and suggest:
- Recommended bump type (patch/minor/major)
- Suggested new version
- Summary of changes by category

## Step 3: Run checks

Detect and run the project's check/test command:

```bash
# Auto-detect: try common check commands
if [ -f "pnpm-lock.yaml" ]; then
  pnpm check 2>/dev/null || pnpm test
elif [ -f "yarn.lock" ]; then
  yarn run check 2>/dev/null || yarn test
elif [ -f "package-lock.json" ]; then
  npm run check 2>/dev/null || npm test
elif [ -f "Cargo.toml" ]; then
  cargo test
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  pytest
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  ./gradlew check
elif [ -f "Makefile" ]; then
  make test
fi
```

Report pass/fail for each check.

## Step 4: Coverage check (optional)

Run coverage if available and report the percentage.

## Step 5: Build verification

```bash
# Auto-detect build command
if [ -f "pnpm-lock.yaml" ]; then
  pnpm build
elif [ -f "Cargo.toml" ]; then
  cargo build --release
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  ./gradlew build
fi
```

Confirm build succeeds and report output size.

## Step 6: CHANGELOG review

Read CHANGELOG.md (if exists) and check:
- Is there content under `## [Unreleased]`?
- Are there commits that aren't reflected in the changelog?
- Are version comparison links up to date?

## Final report

Print a summary table:

```
## Preflight Report

| Check              | Status | Notes                    |
|--------------------|--------|--------------------------|
| Branch             | ...    | feature/xxx              |
| Working tree       | ...    | clean / N files modified |
| gh auth            | ...    | authenticated as USER    |
| Typecheck          | ...    |                          |
| Lint               | ...    |                          |
| Tests              | ...    | N passed, N failed       |
| Coverage           | ...    | XX%                      |
| Build              | ...    | dist/ XXkb               |
| Changelog          | ...    | up to date / needs update|
| Suggested version  | ...    | X.Y.Z (bump_type)       |

Ready for release: YES / NO
```

If all checks pass, suggest running `/release` with the detected bump type.
If any check fails, list what needs to be fixed first.
