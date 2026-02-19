---
name: release
description: Full release workflow - changelog, tests, PR, merge, tag, publish. Use /release [patch|minor|major] or /release (auto-detect).
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task, WebFetch
---

# Release Workflow

You are executing a full release cycle for this project. Follow every step in order. Do NOT skip steps. Do NOT add "Co-Authored-By" to any commit or PR.

## Input

- `$ARGUMENTS` = version bump type: `patch`, `minor`, or `major`
- If empty, auto-detect from commits since last tag using conventional commits:
  - `feat` commits -> `minor`
  - `fix`/`refactor`/`docs`/`chore` only -> `patch`
  - `BREAKING CHANGE` or `!` in commit -> `major`

## Pre-flight checks

Before starting, verify all of these. If any fail, STOP and report:

```bash
# Must be on a feature branch, not main/master
git branch --show-current

# Must have a clean working tree
git status --porcelain

# Must be authenticated with GitHub
gh auth status

# Must have the remote configured
git remote -v
```

## Step 1: Determine version

```bash
# Get last tag
git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"

# Get commits since last tag
git log $(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~50")..HEAD --oneline --no-decorate
```

- Parse current version from `package.json` (or equivalent version file)
- Apply bump type to calculate new version
- Store as `NEW_VERSION` (e.g., `1.8.0`) and `NEW_TAG` (e.g., `v1.8.0`)

## Step 2: Update CHANGELOG.md

Read `CHANGELOG.md` and the [changelog-guide.md](changelog-guide.md) for format rules.

- Move everything under `## [Unreleased]` into a new `## [NEW_VERSION] - YYYY-MM-DD` section
- Categorize commits into: Added, Changed, Improved, Fixed, Removed, Documentation
- Write clear, user-facing descriptions (not raw commit messages)
- Leave `## [Unreleased]` empty for future changes
- Add the new version link at the bottom of the file

## Step 3: Update README.md

Read the current README.md. Only update if:
- There are new features that should be highlighted
- Installation instructions changed
- There are breaking changes that affect usage

If no relevant changes, skip this step and say so.

## Step 4: Bump version

```bash
# Use npm version without git tag (we tag manually later)
npm version NEW_VERSION --no-git-tag-version
```

For non-Node projects, update the version in the appropriate file (Cargo.toml, pyproject.toml, build.gradle, etc.).

## Step 5: Run full checks

Detect and run the project's check command. If ANY check fails:
1. Read the error output carefully
2. Fix the issue
3. Run checks again
4. Repeat until all checks pass (max 5 attempts)

If after 5 attempts checks still fail, STOP and report the issue.

## Step 6: Commit

Stage only the relevant files and commit:

```bash
git add CHANGELOG.md README.md package.json
git commit -m "chore(release): bump version to NEW_VERSION"
```

IMPORTANT:
- Do NOT add `Co-Authored-By` to the commit message
- Do NOT use `--no-verify`
- Only stage files that were actually modified

## Step 7: Push branch

```bash
git push origin $(git branch --show-current)
```

## Step 8: Create PR to main

Create a PR using the template from [pr-template.md](pr-template.md).

```bash
gh pr create --base main --title "chore(release): vNEW_VERSION" --body "BODY_FROM_TEMPLATE"
```

IMPORTANT:
- Do NOT add `Co-Authored-By` in the PR body
- Fill in the template with actual changes from the changelog
- Include the version number and key changes

## Step 9: Wait for CI checks

```bash
gh pr checks --watch
```

If any check fails:
1. Read the failure details: `gh pr checks`
2. Get the failing run logs if needed: `gh run view RUN_ID --log-failed`
3. Fix the issue locally
4. Commit the fix: `git commit -m "fix: resolve CI failure in AREA"`
5. Push: `git push`
6. Wait again: `gh pr checks --watch`
7. Repeat until all checks pass (max 5 cycles)

If after 5 cycles checks still fail, STOP and report.

## Step 10: Merge PR to main

```bash
gh pr merge --squash --delete-branch
```

## Step 11: Create and push tag

```bash
git checkout main
git pull origin main
git tag vNEW_VERSION
git push origin vNEW_VERSION
```

## Step 12: Verify deployment

```bash
# Wait for the release workflow to start
sleep 5
gh run list --workflow=release.yml --limit=1
```

Once the workflow completes, confirm the release was created:
```bash
gh release view vNEW_VERSION
```

## Final report

Print a summary:

```
## Release vNEW_VERSION complete

- Changelog: updated
- README: updated / no changes needed
- Tests: all passing
- PR: #NUMBER (merged)
- Tag: vNEW_VERSION
```
