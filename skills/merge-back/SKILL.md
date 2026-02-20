---
name: merge-back
description: Merge changes from an isolated project copy back to the original project. Use after finishing work in a forked copy.
disable-model-invocation: true
allowed-tools:
  - Bash
---

# Merge Back

Brings changes from a forked project copy back to the original project.

## What it does

1. **Validates** the copy exists and has no uncommitted changes
2. **Runs checks** in the copy to ensure quality (auto-detects test/check scripts)
3. **Adds** the copy as a temporary git remote in the original (`fork-project` removed it intentionally to prevent accidental pushes — this is expected)
4. **Merges** the copy's `work/<feature-name>` branch directly into `main`
5. **Cleans up** the temporary remote
6. **Optionally deletes** the copy directory with `--cleanup`

## Usage

```
/merge-back <feature-name> [--cleanup]
```

Pass `--cleanup` to automatically delete the copy directory after a successful merge.

## How to execute

**This must be run from the ORIGINAL project directory** (not the copy).

```bash
bash .claude/skills/merge-back/scripts/merge-back.sh "<feature-name>"
# or with automatic cleanup:
bash .claude/skills/merge-back/scripts/merge-back.sh "<feature-name>" --cleanup
```

Where `<feature-name>` matches the name used when running `/fork-project`.

## Important

- The copy must have all changes committed (no dirty working tree)
- Tests/checks are run in the copy before merging — if they fail, the merge is aborted
- Merges directly into `main` (no intermediate review branch)
- If there are merge conflicts, the script stops and gives instructions for manual resolution
- Use `git reset --hard ORIG_HEAD` to undo the merge if needed
- The merge preserves full commit history from the copy
- Without `--cleanup`, the copy is kept — run `/cleanup-copy <feature-name>` when done
