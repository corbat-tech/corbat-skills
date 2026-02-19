#!/bin/bash
set -euo pipefail

# =============================================================================
# merge-back.sh - Merge changes from an isolated copy back to the original
# =============================================================================
# Usage: merge-back.sh <feature-name> [original-dir]
#
# Brings changes from a forked copy back to the original project using
# standard git merge (possible because we used git clone, so histories share
# a common ancestor).
#
# Arguments:
#   feature-name  Name of the feature/copy (e.g., "auth-refactor")
#   original-dir  Original project directory (default: current directory)
#
# What it does:
#   1. Validates the copy exists and has committed changes
#   2. Runs checks (tests, lint) in the copy
#   3. Adds the copy as a temporary remote
#   4. Fetches and merges into a new branch
#   5. Removes the temporary remote
# =============================================================================

FEATURE_NAME="${1:?Error: feature name required. Usage: merge-back.sh <feature-name> [original-dir]}"

# Validate feature name: only allow alphanumeric, hyphens, underscores, and dots
if [[ ! "$FEATURE_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Error: invalid feature name '$FEATURE_NAME'"
  echo "Only alphanumeric characters, hyphens, underscores, and dots are allowed."
  exit 1
fi

ORIGINAL_DIR="${2:-$(pwd)}"

# Resolve absolute path
ORIGINAL_DIR="$(cd "$ORIGINAL_DIR" && pwd)"
PROJECT_NAME="$(basename "$ORIGINAL_DIR")"
PARENT_DIR="$(dirname "$ORIGINAL_DIR")"
COPY_DIR="${PARENT_DIR}/${PROJECT_NAME}_copy_${FEATURE_NAME}"
REMOTE_NAME="copy_${FEATURE_NAME}"
MERGE_BRANCH="merge/${FEATURE_NAME}"

# --- Validations ---

if [ ! -d "$COPY_DIR" ]; then
  echo "Error: copy not found at $COPY_DIR"
  echo "Available copies:"
  ls -d "${PARENT_DIR}/${PROJECT_NAME}_copy_"* 2>/dev/null || echo "  (none)"
  exit 1
fi

if [ ! -d "$COPY_DIR/.git" ]; then
  echo "Error: $COPY_DIR is not a git repository"
  exit 1
fi

if [ ! -d "$ORIGINAL_DIR/.git" ]; then
  echo "Error: $ORIGINAL_DIR is not a git repository"
  exit 1
fi

# Check copy has no uncommitted changes
cd "$COPY_DIR"
if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet HEAD 2>/dev/null; then
  echo "Error: there are uncommitted changes in the copy at $COPY_DIR"
  echo "Please commit or stash all changes in the copy before merging back."
  exit 1
fi

# Check copy branch exists
COPY_BRANCH="work/${FEATURE_NAME}"
if ! git rev-parse --verify "$COPY_BRANCH" >/dev/null 2>&1; then
  echo "Warning: branch $COPY_BRANCH not found in copy."
  COPY_BRANCH=$(git branch --show-current)
  echo "Using current branch: $COPY_BRANCH"
fi

echo "=== Merge Back ==="
echo "Copy:     $COPY_DIR"
echo "Original: $ORIGINAL_DIR"
echo "Branch:   $COPY_BRANCH -> $MERGE_BRANCH"
echo ""

# --- Phase 1: Pre-merge checks in the copy ---

echo "[1/5] Running pre-merge checks in the copy..."
cd "$COPY_DIR"

# Check if there are actual changes compared to the base
COMMIT_COUNT=$(git rev-list --count main..HEAD 2>/dev/null || echo "0")
if [ "$COMMIT_COUNT" = "0" ]; then
  echo "Warning: no commits found on top of main in the copy."
  echo "Are you sure there are changes to merge?"
  echo ""
fi

# Detect package manager
detect_pkg_manager() {
  if [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "package-lock.json" ]; then echo "npm"
  elif [ -f "package.json" ]; then echo "npm"
  else echo ""
  fi
}

# Run tests if available
if [ -f "package.json" ]; then
  PKG_MGR=$(detect_pkg_manager)
  HAS_CHECK=$(node --input-type=commonjs -e "const p=require('./package.json'); console.log(p.scripts?.check ? 'yes' : 'no')" 2>/dev/null || echo "no")
  HAS_TEST=$(node --input-type=commonjs -e "const p=require('./package.json'); console.log(p.scripts?.test ? 'yes' : 'no')" 2>/dev/null || echo "no")

  if [ "$HAS_CHECK" = "yes" ]; then
    echo "  Running checks in copy ($PKG_MGR)..."
    if ! "$PKG_MGR" run check 2>&1; then
      echo ""
      echo "Error: checks failed in the copy. Fix issues before merging."
      exit 1
    fi
    echo "  Checks passed."
  elif [ "$HAS_TEST" = "yes" ]; then
    echo "  Running tests in copy ($PKG_MGR)..."
    if ! "$PKG_MGR" test 2>&1; then
      echo ""
      echo "Error: tests failed in the copy. Fix issues before merging."
      exit 1
    fi
    echo "  Tests passed."
  else
    echo "  No test/check script found, skipping."
  fi
elif [ -f "Cargo.toml" ]; then
  echo "  Running cargo test in copy..."
  if ! cargo test 2>&1; then
    echo ""
    echo "Error: tests failed in the copy. Fix issues before merging."
    exit 1
  fi
  echo "  Tests passed."
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  echo "  Running pytest in copy..."
  if ! pytest 2>&1; then
    echo ""
    echo "Error: tests failed in the copy. Fix issues before merging."
    exit 1
  fi
  echo "  Tests passed."
fi
echo ""

# --- Phase 2: Add remote and fetch ---

cd "$ORIGINAL_DIR"

echo "[2/5] Ensuring clean state in original..."
if ! git diff --quiet HEAD 2>/dev/null; then
  echo "Warning: there are uncommitted changes in the original."
  echo "Stashing them before merge..."
  git stash push -m "auto-stash before merge-back ${FEATURE_NAME}"
  STASHED=true
else
  STASHED=false
fi

cleanup_stash() {
  if [ "$STASHED" = "true" ]; then
    cd "$ORIGINAL_DIR" 2>/dev/null || true
    git stash pop 2>/dev/null || true
  fi
}
trap cleanup_stash EXIT

echo "[3/5] Adding copy as temporary remote..."
# Remove remote if it already exists (from a previous failed attempt)
git remote remove "$REMOTE_NAME" 2>/dev/null || true
git remote add "$REMOTE_NAME" "$COPY_DIR"
git fetch "$REMOTE_NAME"

# --- Phase 3: Create merge branch and merge ---

echo "[4/5] Creating merge branch and merging..."

# Ensure we're on main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "  Switching to main..."
  git checkout main
fi

# Delete merge branch if it exists (from a previous attempt)
git branch -D "$MERGE_BRANCH" 2>/dev/null || true

# Create merge branch from main
git checkout -b "$MERGE_BRANCH"

# Merge the copy's work branch
if ! git merge "${REMOTE_NAME}/${COPY_BRANCH}" --no-edit -m "feat: merge ${FEATURE_NAME} from isolated copy"; then
  echo ""
  echo "=== MERGE CONFLICT ==="
  echo "There are merge conflicts. Please resolve them manually:"
  echo "  1. Fix the conflicts in the files listed above"
  echo "  2. Run: git add . && git commit"
  echo "  3. Then run: /cleanup-copy $FEATURE_NAME"
  echo ""
  echo "The temporary remote '$REMOTE_NAME' is still configured."
  exit 1
fi

# --- Phase 4: Cleanup remote ---

echo "[5/5] Cleaning up temporary remote..."
git remote remove "$REMOTE_NAME"

echo ""

# --- Summary ---

echo "=== Merge Complete ==="
echo ""
echo "Changes merged into branch: $MERGE_BRANCH"
echo "Commits merged: $COMMIT_COUNT"
echo ""
echo "You are now on branch '$MERGE_BRANCH'. Review the changes:"
echo "  git log --oneline main..$MERGE_BRANCH"
echo "  git diff main..$MERGE_BRANCH --stat"
echo ""
echo "Next steps:"
echo "  1. Review the merged changes"
echo "  2. Run /cleanup-copy $FEATURE_NAME to delete the copy"
echo "  3. Run /release-pr to create a PR and tag"
echo ""
echo "Or to undo the merge:"
echo "  git checkout main && git branch -D $MERGE_BRANCH"
echo ""
