# corbat-skills

Reusable AI agent skills for parallel development, code quality, and release automation.

15 production-ready skills following the open [SKILL.md](https://agentskills.io) standard — compatible with Claude Code, Cursor, Copilot, Cline, Codex, and other agents.

## Skills

### Code Quality

| Skill | Description |
|---|---|
| [`/code-review`](skills/code-review/) | Review and score code across 12 quality dimensions (0-100). Read-only. |
| [`/code-fix`](skills/code-fix/) | Apply prioritized fixes (P0 → P3). Single pass with verification. |
| [`/coco-fix-iterate`](skills/coco-fix-iterate/) | Autonomous loop: review → score → fix → verify → re-score until target. |

### Parallel Development

#### Worktree-based (recommended for parallel agents)

| Skill | Description |
|---|---|
| [`/worktree-start`](skills/worktree-start/) | Create a git worktree for isolated parallel feature development. Lighter than fork — shared git history, zero agent contention. |
| [`/worktree-finish`](skills/worktree-finish/) | Merge a worktree branch into main and clean up the worktree. |
| [`/worktree-list`](skills/worktree-list/) | List active worktrees with branch, commits ahead of main, and dirty status. |

#### Fork-based (maximum isolation, separate `.git`)

| Skill | Description |
|---|---|
| [`/fork-project`](skills/fork-project/) | Create an isolated project copy (full clone) for parallel feature development. |
| [`/merge-back`](skills/merge-back/) | Merge changes from a copy back to the original project. |
| [`/cleanup-copy`](skills/cleanup-copy/) | Delete a copy after merge-back is complete. |
| [`/new-feature`](skills/new-feature/) | Start a new feature (fork + setup instructions). |
| [`/finish-feature`](skills/finish-feature/) | Complete a feature (merge + cleanup + optional release). |

### Release Automation

| Skill | Description |
|---|---|
| [`/preflight`](skills/preflight/) | Run all validation checks without releasing. |
| [`/hotfix`](skills/hotfix/) | Quick patch release for urgent fixes. |
| [`/release-pr`](skills/release-pr/) | Create release from merge branch (bump, tag, push). |
| [`/release`](skills/release/) | Full release workflow (changelog, tests, PR, merge, tag). |

## `/coco-fix-iterate` — The Highlight

The star skill. An autonomous convergence loop that no one else offers as a standalone skill.

```
/coco-fix-iterate                              # Score >= 85, max 10 iterations
/coco-fix-iterate --score 90                   # Higher quality bar
/coco-fix-iterate --max-iterations 5 security  # Focus on security
```

How it works:

```
┌─────────┐     ┌───────┐     ┌──────┐     ┌────────┐     ┌────────┐
│ REVIEW  │ ──→ │ SCORE │ ──→ │ PLAN │ ──→ │  FIX   │ ──→ │ VERIFY │
│ 12 dims │     │ 0-100 │     │ P0→P2│     │ apply  │     │ tests  │
└─────────┘     └───┬───┘     └──────┘     └────────┘     └───┬────┘
     ↑              │                                          │
     │              │  score >= target AND delta < 2?          │
     │              │  ──→  CONVERGED. STOP.                   │
     │              │                                          │
     └──────────────┴──────────── RE-SCORE ←───────────────────┘
```

**Stops when:** score meets target, scores oscillate, diminishing returns, or max iterations reached.

## Scoring System (12 Dimensions)

| Dimension | Weight | What it measures |
|---|---|---|
| Correctness | 15% | Tests pass, build succeeds, logic errors |
| Completeness | 10% | Requirements met, edge cases, TODO items |
| Robustness | 10% | Error handling, null checks, boundaries |
| Readability | 10% | Naming, function size, organization |
| Maintainability | 10% | Coupling, cohesion, SRP, DRY |
| Complexity | 8% | Cyclomatic complexity, nesting depth |
| Duplication | 7% | Copy-paste code, repeated patterns |
| Test Coverage | 10% | Line/branch coverage, critical paths |
| Test Quality | 5% | Meaningful assertions, edge cases |
| Security | 8% | OWASP top 10, injection, secrets |
| Documentation | 4% | Public API docs, README accuracy |
| Style | 3% | Lint compliance, formatting |

## Installation

### Clone and install manually

```bash
git clone https://github.com/corbat-tech/corbat-skills.git
bash corbat-skills/install.sh /path/to/your/project
```

### Install specific skills only

```bash
bash install.sh /path/to/your/project code-review code-fix coco-fix-iterate
```

This copies skills into your project's `.claude/skills/` directory.

## Skill Types

Skills come in two flavors:

| Type | How it runs | Examples |
|---|---|---|
| **Script-based** | Has a bash script in `scripts/` — the agent runs it | fork-project, merge-back, cleanup-copy, release-pr |
| **Agent-implemented** | Agent reads SKILL.md and follows the steps | code-review, code-fix, coco-fix-iterate, preflight, hotfix, release |

Script-based skills can also be run manually from any terminal.

## Compatibility

Works with any agent supporting the [SKILL.md standard](https://agentskills.io):

- Claude Code
- GitHub Copilot
- Cursor
- Cline
- OpenAI Codex
- Gemini CLI

## Requirements

- **git** — All skills use git for version control
- **gh** (optional) — GitHub CLI, needed for PR/release skills
- **Node.js** (optional) — For projects with `package.json` (version bump, script detection)
- **Package manager** — Skills auto-detect pnpm, yarn, or npm

## License

MIT
