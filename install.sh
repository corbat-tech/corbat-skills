#!/bin/bash
set -euo pipefail

# =============================================================================
# install.sh - Install corbat-skills into a project
# =============================================================================
# Usage: install.sh <target-project> [skill1 skill2 ...]
#
# If no skills are specified, all skills are installed.
# Skills are copied into <target-project>/.claude/skills/
# =============================================================================

TARGET="${1:?Error: target project path required. Usage: install.sh <target-project> [skill1 skill2 ...]}"
shift

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
TARGET="$(cd "$TARGET" && pwd)"
TARGET_SKILLS="${TARGET}/.claude/skills"

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory does not exist: $TARGET"
  exit 1
fi

# Determine which skills to install
if [ $# -eq 0 ]; then
  # Install all skills
  SKILLS=($(ls -d "$SKILLS_DIR"/*/  | xargs -I{} basename {}))
else
  SKILLS=("$@")
fi

# Install
mkdir -p "$TARGET_SKILLS"

INSTALLED=0
SKIPPED=0

for skill in "${SKILLS[@]}"; do
  SRC="${SKILLS_DIR}/${skill}"
  DST="${TARGET_SKILLS}/${skill}"

  if [ ! -d "$SRC" ]; then
    echo "  Warning: skill '$skill' not found, skipping"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Copy skill (overwrite if exists)
  rm -rf "$DST"
  cp -r "$SRC" "$DST"

  # Make scripts executable
  if [ -d "$DST/scripts" ]; then
    chmod +x "$DST/scripts/"*.sh 2>/dev/null || true
  fi

  echo "  Installed: $skill"
  INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "Done. Installed $INSTALLED skill(s) to $TARGET_SKILLS"
[ "$SKIPPED" -gt 0 ] && echo "Skipped $SKIPPED skill(s) (not found)"
echo ""
