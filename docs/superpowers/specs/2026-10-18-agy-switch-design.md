# agy-switch Design Specification
# Date: 2026-10-18

## Intent and Why

`agy-switch` is a shell tool for developers who maintain multiple Google
Antigravity (AGY) accounts on a single Linux machine — e.g. a personal
account and a work account. AGY stores OAuth credentials in a single file
at `~/.gemini/antigravity-cli/antigravity-oauth-token`; there is no native
multi-account mechanism. The tool manages named credential snapshots
("profiles") and swaps the active file on demand.

## Goals

- Save the currently authenticated AGY account as a named profile
- Switch the active account by name (one command)
- List all profiles with a visible active-profile marker
- Delete profiles that are no longer needed
- Report the currently active profile name
- First-time `init` command bootstraps the default profile
- Works entirely as a self-contained bash script with no dependencies
  beyond coreutils and bash ≥ 4

## Non-Goals

- Browser-based OAuth login (users must authenticate via `agy` themselves)
- Encryption of stored credentials at rest
- Windows support
- Cross-machine synchronisation

## Anti-Goals (failure even if technically working)

- Silently deleting the active profile — must guard with an error
- Committing credentials to git — `.gitignore` must exclude `profiles/`
- Allowing profile names with spaces or special characters — must validate

## Constraints

- Shell: bash ≥ 4, `set -euo pipefail`
- No external dependencies beyond coreutils
- Profile storage: `~/.gemini/antigravity-cli/profiles/<name>/`
- Token file: `~/.gemini/antigravity-cli/antigravity-oauth-token`
- Settings file: `~/.gemini/antigravity-cli/settings.json`
- Active profile marker: `~/.gemini/antigravity-cli/.agy-current-profile`
- Profile name format: `[a-zA-Z0-9_-]+` (validated with regex)
- Test suite: bats (Bash Automated Testing System) ≥ 1.0
- Tests live in `tests/` directory
- Script must be executable and PATH-installable via symlink

## Commands

| Command | Behaviour |
|---------|-----------|
| `agy-switch init` | Create profiles dir; save current token as `default`; write marker |
| `agy-switch list` | Print all profile names; mark active with `*` |
| `agy-switch save <name>` | Copy token+settings into `profiles/<name>/`; validate name |
| `agy-switch use <name>` | Copy profile files to active paths; write marker |
| `agy-switch current` | Print active profile from marker file |
| `agy-switch delete <name>` | Remove profile dir; guard against deleting active profile |
| `agy-switch help` | Print usage |

## Parts Left to Builder

- Exact colour codes and TTY detection
- Bats helper fixtures (fake token/settings files)
- Git commit message wording
