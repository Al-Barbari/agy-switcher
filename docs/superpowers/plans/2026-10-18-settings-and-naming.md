# Settings Mode & Multi-Account Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add configurable settings sharing (`per-profile` vs `shared`), auto-save on switch, profile renaming, interactive profile switching, guided account creation, and reserved keyword validation to `agy-switch`.

**Architecture:** Extend `agy-switch` bash script with modular commands and helper functions. Persist settings mode in `${AGY_DIR}/.agy-settings-mode`. Cover each new feature with Bats test suites under `tests/`.

**Tech Stack:** bash >= 4, bats 1.10.0, coreutils, git

**Spec:** `docs/superpowers/specs/2026-10-18-settings-and-naming.md`

## Global Constraints
- bash >= 4, `set -euo pipefail`
- Profile name regex: `^[a-zA-Z0-9_-]+$`
- Reserved keywords rejected as profile names: `init`, `list`, `save`, `use`, `current`, `delete`, `rename`, `add`, `settings`, `help`
- Default settings mode is `per-profile`
- Mode file stored at `${AGY_DIR}/.agy-settings-mode`
- All bats tests must pass: `bats tests/`
- All changes stay on `development` branch (no push to `main`)

## Tasks

### Task 1: Reserved keywords validation & Profile Name Guard
- Create `tests/test_validation.bats`
- Disallow reserved names (`settings`, `rename`, `add`, `list`, etc.) in `cmd_save`
- Write tests: saving with reserved names fails with exit 1 and helpful error
- Implement keyword check in `_validate_profile_name()`

### Task 2: Configurable Settings Mode (`agy-switch settings [per-profile|shared]`)
- Create `tests/test_settings_mode.bats`
- Implement `cmd_settings`:
  - `agy-switch settings`: print current mode
  - `agy-switch settings per-profile`: set mode to per-profile
  - `agy-switch settings shared`: set mode to shared
  - Reject invalid modes
- In `cmd_use`:
  - If mode is `per-profile`:
    - Auto-save current active profile's `settings.json` before swapping
    - Restore target profile's `settings.json`
  - If mode is `shared`:
    - Do NOT swap or overwrite `settings.json`

### Task 3: Profile Renaming (`agy-switch rename <old> <new>`)
- Create `tests/test_rename.bats`
- Implement `cmd_rename`:
  - Require `<old>` and `<new>` arguments
  - Validate `<old>` exists and `<new>` is a valid, non-reserved name that does not exist
  - Move `profiles/<old>` to `profiles/<new>`
  - If `<old>` is the active profile, update `.agy-current-profile` to `<new>`

### Task 4: Interactive Switcher & Guided Add
- Create `tests/test_interactive_use.bats` and `tests/test_add.bats`
- In `cmd_use`:
  - When no argument passed, list numbered profiles and prompt for selection
- In `cmd_add <name>`:
  - Validate `<name>` is valid, non-reserved, and doesn't exist
  - Print guided instructions to run `agy` and complete setup

### Task 5: Documentation & Full Suite Verification
- Update `README.md` with the new commands and documentation
- Run full Bats test suite (`bats tests/`)
- Ensure all tests pass cleanly
