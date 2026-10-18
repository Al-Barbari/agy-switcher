# agy-switch Settings Mode & Multi-Account Specification
# Date: 2026-10-18

## Intent and Why
Users want flexibility in how preferences (e.g. active AI model, agent mode, trusted workspaces) are handled when switching between accounts:
1. Some users want each account to maintain its own independent preferences (e.g. work account uses Gemini Flash with work workspaces; personal account uses Claude Sonnet with personal workspaces), with changes preserved automatically across switches.
2. Other users want a single unified preference configuration across all accounts so changing the model once applies everywhere.

In addition, users manage unlimited named accounts and need first-class profile lifecycle capabilities: renaming, interactive selection, guided creation, and reserved word validation.

## Goals
- Support configurable settings sharing: `per-profile` (default) vs `shared`.
- In `per-profile` mode: automatically snapshot the active profile's `settings.json` before switching away.
- In `shared` mode: only swap `antigravity-oauth-token`, leaving `settings.json` unchanged.
- Command: `agy-switch settings [per-profile|shared]` to inspect or toggle mode.
- Command: `agy-switch rename <old> <new>` to rename a profile and update current profile pointer if active.
- Command: `agy-switch add <name>` to guide account creation with validation.
- Interactive `agy-switch use` (with no arguments): prompt numbered list to choose profile.
- Strict profile name validation: reject reserved keywords (`help`, `init`, `list`, `save`, `use`, `current`, `delete`, `rename`, `add`, `settings`) and invalid characters.

## Non-Goals
- Web-based OAuth automation (login still happens via `agy` TUI).
- Partial settings sync (e.g. sharing only model but not workspaces).

## Constraints
- Shell: bash >= 4, `set -euo pipefail`.
- No external dependencies beyond coreutils and standard bash builtins.
- Settings mode stored in `${AGY_DIR}/.agy-settings-mode`. Defaults to `per-profile` if missing.
- All bats tests must pass: `bats tests/`.
