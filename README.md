# Corbat Skills

Reusable agent skills for parallel development, quality gates, and release automation.

## Skills

### Parallel Development

| Skill | Description |
|---|---|
| `/fork-project` | Create an isolated copy of a project for parallel feature work |
| `/new-feature` | Start a new feature (orchestrates fork-project + setup) |
| `/merge-back` | Merge changes from a forked copy back to the original |
| `/cleanup-copy` | Delete a forked copy after merge-back |
| `/finish-feature` | Full workflow: merge-back + cleanup + optional release |

### Code Quality

| Skill | Description |
|---|---|
| `/code-review` | Review and score code quality (read-only, no changes) |
| `/code-fix` | Apply prioritized fixes based on review findings (single pass) |
| `/coco-fix-iterate` | Iterative quality loop: review, score, fix, verify until target score |

### Release

| Skill | Description |
|---|---|
| `/preflight` | Run all validation checks without releasing |
| `/hotfix` | Quick patch release for urgent fixes |
| `/release-pr` | Create a release from a merge branch (bump, tag, push) |
| `/release` | Full release workflow (changelog, PR, CI, merge, tag, publish) |

## Installation

### Single command (via skills.sh)

```bash
npx skillsadd corbat/corbat-skills
```

### Manual (copy to your project)

```bash
bash install.sh /path/to/your/project
```

This copies all skills into your project's `.claude/skills/` directory.

### Install specific skills only

```bash
bash install.sh /path/to/your/project fork-project merge-back code-review
```

## Compatibility

These skills use the open [Agent Skills](https://agentskills.io) standard (`SKILL.md` format) and work with:

- Claude Code
- GitHub Copilot
- Cursor
- Cline
- OpenAI Codex
- Gemini CLI
- And other agents supporting the SKILL.md standard

The bash scripts in `scripts/` directories can be used standalone from any terminal.

## Requirements

- **git** - All skills use git for version control
- **gh** (optional) - GitHub CLI for PR/release skills
- **Node.js** (optional) - For projects with `package.json`
- **Package manager** - Skills auto-detect pnpm, yarn, or npm

## License

MIT
