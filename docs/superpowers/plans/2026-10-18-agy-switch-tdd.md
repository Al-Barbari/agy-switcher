# agy-switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Retrofit the existing `agy-switch` bash script with a full bats test suite (TDD RED→GREEN per command) and proper project structure so the tool meets superpowers quality standards.

**Architecture:** Single self-contained bash script (`agy-switch`) tested via bats. Tests live in `tests/` and use a temporary fake AGY home directory (fixtures) so no real credentials are touched. The existing implementation is refactored only where tests reveal gaps.

**Tech Stack:** bash ≥ 4, bats 1.10.0, coreutils, git

**Spec:** `docs/superpowers/specs/2026-10-18-agy-switch-design.md`

## Global Constraints

- bash ≥ 4, `set -euo pipefail` — existing script already uses this
- Profile name regex: `[a-zA-Z0-9_-]+` — validated in `save` and `use`
- Profile storage: `~/.gemini/antigravity-cli/profiles/<name>/` — overridden in tests via `AGY_DIR` env var
- Token file path overridable via `AGY_DIR` — required for test isolation
- All bats tests must pass: `bats tests/`
- No credentials committed — `profiles/` in `.gitignore`
- Script remains a single file at repo root

## Review Focus

1. **Missing token file** — `save` and `init` with no token file at `$TOKEN_FILE` must exit 1 with a clear error, not a silent cp failure
2. **Profile name with spaces** — `save "bad name"` must reject with exit 1 and print the validation error
3. **`use` on already-active profile** — must print a warning and exit 0 (not 1), so callers don't treat it as an error
4. **`delete` on active profile** — must exit 1 with a clear guard message
5. **`list` with no profiles** — must print a friendly "no profiles yet" message, not an error or empty output

---

### Task 1: Test infrastructure — bats fixtures and helpers

**Files:**
- Create: `tests/helpers.bash`
- Create: `tests/fixtures/fake-token.json`
- Create: `tests/fixtures/fake-settings.json`

**Interfaces:**
- Consumes: nothing
- Produces: `setup_fake_agy_dir()` helper (sets `AGY_DIR` to a fresh tmp dir, copies fixtures in, exports `AGY_DIR`); `teardown_fake_agy_dir()` helper (removes tmp dir). Both sourced via `load helpers` in every test file.

- [ ] **Step 1: Write a failing bats test that loads the helper**

```bash
# tests/test_helpers.bats
@test "helpers: setup creates AGY_DIR with token file" {
  setup_fake_agy_dir
  [ -f "$AGY_DIR/antigravity-oauth-token" ]
  teardown_fake_agy_dir
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `bats tests/test_helpers.bats`
Expected: FAIL — `helpers.bash` does not exist

- [ ] **Step 3: Create `tests/fixtures/fake-token.json`**

```json
{"token":{"access_token":"fake-access","refresh_token":"fake-refresh","token_type":"Bearer","expiry":"2099-01-01T00:00:00Z"},"auth_method":"consumer","id_token":"fake-id"}
```

- [ ] **Step 4: Create `tests/fixtures/fake-settings.json`**

```json
{"agentMode":"accept-edits","model":"Gemini Flash","toolPermission":"always-proceed"}
```

- [ ] **Step 5: Create `tests/helpers.bash`**

```bash
# Exports AGY_DIR pointing to a clean tmp directory with fake credentials.
# The agy-switch script reads AGY_DIR from the environment.
setup_fake_agy_dir() {
  export AGY_DIR
  AGY_DIR="$(mktemp -d)"
  cp "$BATS_TEST_DIRNAME/fixtures/fake-token.json" \
     "$AGY_DIR/antigravity-oauth-token"
  cp "$BATS_TEST_DIRNAME/fixtures/fake-settings.json" \
     "$AGY_DIR/settings.json"
}

teardown_fake_agy_dir() {
  rm -rf "$AGY_DIR"
}

# Path to the script under test
AGY_SWITCH="$BATS_TEST_DIRNAME/../agy-switch"
```

- [ ] **Step 6: Run to verify it passes**

Run: `bats tests/test_helpers.bats`
Expected: PASS 1/1

- [ ] **Step 7: Commit**

```bash
git add tests/
git commit -m "test: add bats test infrastructure (helpers + fixtures)"
```

---

### Task 2: Make `agy-switch` respect `AGY_DIR` env override

**Files:**
- Modify: `agy-switch` (lines 20-27, the path-definition block)

**Interfaces:**
- Consumes: nothing from Task 1 code; uses `AGY_DIR` env var convention established by Task 1's helpers
- Produces: `agy-switch` reads `AGY_DIR` from environment if set, falls back to `~/.gemini/antigravity-cli`; all internal path variables (`PROFILES_DIR`, `TOKEN_FILE`, etc.) derive from `AGY_DIR`

- [ ] **Step 1: Write the failing test**

```bash
# tests/test_env_override.bats
load helpers
@test "env: AGY_DIR override is respected for profiles dir" {
  setup_fake_agy_dir
  run bash "$AGY_SWITCH" init
  [ -d "$AGY_DIR/profiles/default" ]
  teardown_fake_agy_dir
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `bats tests/test_env_override.bats`
Expected: FAIL — init creates profiles in real `~/.gemini/antigravity-cli/profiles/`, not in `$AGY_DIR`

- [ ] **Step 3: Modify `agy-switch` path block**

Replace the hardcoded `AGY_DIR` assignment with:
```bash
AGY_DIR="${AGY_DIR:-${HOME}/.gemini/antigravity-cli}"
```
(All downstream variables `PROFILES_DIR`, `TOKEN_FILE`, `SETTINGS_FILE`, `CURRENT_FILE` already derive from `$AGY_DIR` — no other changes needed.)

- [ ] **Step 4: Run to verify it passes**

Run: `bats tests/test_env_override.bats`
Expected: PASS 1/1

- [ ] **Step 5: Commit**

```bash
git add agy-switch tests/test_env_override.bats
git commit -m "feat: respect AGY_DIR env var for test isolation"
```

---

### Task 3: Tests for `init` command

**Files:**
- Create: `tests/test_init.bats`

**Interfaces:**
- Consumes: `setup_fake_agy_dir` / `teardown_fake_agy_dir` from Task 1; `AGY_DIR` override from Task 2
- Produces: nothing consumed by later tasks

- [ ] **Step 1: Write failing tests**

```bash
# tests/test_init.bats
load helpers

setup()    { setup_fake_agy_dir; }
teardown() { teardown_fake_agy_dir; }

@test "init: creates profiles/default directory" {
  run bash "$AGY_SWITCH" init
  [ "$status" -eq 0 ]
  [ -d "$AGY_DIR/profiles/default" ]
}

@test "init: copies token into default profile" {
  run bash "$AGY_SWITCH" init
  [ -f "$AGY_DIR/profiles/default/antigravity-oauth-token" ]
}

@test "init: writes default to current-profile marker" {
  run bash "$AGY_SWITCH" init
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "default" ]
}

@test "init: is idempotent (safe to run twice)" {
  bash "$AGY_SWITCH" init
  run bash "$AGY_SWITCH" init
  [ "$status" -eq 0 ]
}

@test "init: fails when no token file present" {
  rm "$AGY_DIR/antigravity-oauth-token"
  run bash "$AGY_SWITCH" init
  [ "$status" -eq 1 ]
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `bats tests/test_init.bats`
Expected: mix of PASS (init mostly works) and FAIL for idempotent + missing-token tests

- [ ] **Step 3: Fix `cmd_init` idempotent guard**

Current guard prints warning and exits 0 only when profiles exist AND `ls "${PROFILES_DIR}/"*` succeeds. Confirm this works with the env override by running once manually in a tmp dir.

- [ ] **Step 4: Run all init tests to verify they pass**

Run: `bats tests/test_init.bats`
Expected: PASS 5/5

- [ ] **Step 5: Commit**

```bash
git add tests/test_init.bats
git commit -m "test: add bats tests for init command"
```

---

### Task 4: Tests for `save` and `use` commands

**Files:**
- Create: `tests/test_save_use.bats`

**Interfaces:**
- Consumes: helpers from Task 1, AGY_DIR override from Task 2
- Produces: nothing consumed by later tasks

- [ ] **Step 1: Write failing tests**

```bash
# tests/test_save_use.bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "save: creates named profile directory" {
  run bash "$AGY_SWITCH" save personal
  [ "$status" -eq 0 ]
  [ -d "$AGY_DIR/profiles/personal" ]
}

@test "save: copies token into named profile" {
  run bash "$AGY_SWITCH" save personal
  [ -f "$AGY_DIR/profiles/personal/antigravity-oauth-token" ]
}

@test "save: rejects name with spaces" {
  run bash "$AGY_SWITCH" save "bad name"
  [ "$status" -eq 1 ]
}

@test "save: rejects name with special chars" {
  run bash "$AGY_SWITCH" save "bad!"
  [ "$status" -eq 1 ]
}

@test "save: fails with no token file" {
  rm "$AGY_DIR/antigravity-oauth-token"
  run bash "$AGY_SWITCH" save work
  [ "$status" -eq 1 ]
}

@test "use: switches active profile" {
  bash "$AGY_SWITCH" save personal
  run bash "$AGY_SWITCH" use personal
  [ "$status" -eq 0 ]
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "personal" ]
}

@test "use: overwrites active token file with profile token" {
  bash "$AGY_SWITCH" save personal
  echo "old-token" > "$AGY_DIR/antigravity-oauth-token"
  bash "$AGY_SWITCH" use personal
  # token should now match what was saved as personal (original fake token)
  run grep "fake-access" "$AGY_DIR/antigravity-oauth-token"
  [ "$status" -eq 0 ]
}

@test "use: already-active profile exits 0 with warning" {
  run bash "$AGY_SWITCH" use default
  [ "$status" -eq 0 ]
  [[ "$output" == *"already active"* ]]
}

@test "use: nonexistent profile exits 1" {
  run bash "$AGY_SWITCH" use nonexistent
  [ "$status" -eq 1 ]
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `bats tests/test_save_use.bats`
Expected: several failures, especially the already-active warning test

- [ ] **Step 3: Fix any gaps in `cmd_use` — ensure already-active outputs `already active` in the message**

Current `cmd_use` warns with `"Profile '${name}' is already active. No change made."` — confirm this contains `"already active"` (it does). If tests still fail, check that `$output` captures stderr. Adjust `run` to `run bash ... 2>&1` if needed.

- [ ] **Step 4: Run to verify all pass**

Run: `bats tests/test_save_use.bats`
Expected: PASS 9/9

- [ ] **Step 5: Commit**

```bash
git add tests/test_save_use.bats
git commit -m "test: add bats tests for save and use commands"
```

---

### Task 5: Tests for `list`, `current`, and `delete` commands

**Files:**
- Create: `tests/test_list_current_delete.bats`

**Interfaces:**
- Consumes: helpers from Task 1, AGY_DIR override from Task 2
- Produces: nothing consumed by later tasks

- [ ] **Step 1: Write failing tests**

```bash
# tests/test_list_current_delete.bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "list: shows default profile after init" {
  run bash "$AGY_SWITCH" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"default"* ]]
}

@test "list: marks active profile with asterisk" {
  run bash "$AGY_SWITCH" list
  [[ "$output" == *"* default"* ]] || [[ "$output" == *"*"*"default"* ]]
}

@test "list: shows no-profiles message when empty" {
  rm -rf "$AGY_DIR/profiles"
  mkdir -p "$AGY_DIR/profiles"
  run bash "$AGY_SWITCH" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"no profiles"* ]]
}

@test "current: prints active profile name" {
  run bash "$AGY_SWITCH" current
  [ "$status" -eq 0 ]
  [[ "$output" == *"default"* ]]
}

@test "current: warns when no marker file" {
  rm -f "$AGY_DIR/.agy-current-profile"
  run bash "$AGY_SWITCH" current
  [ "$status" -eq 0 ]
  [[ "$output" == *"none"* ]] || [[ "$output" == *"No profile"* ]]
}

@test "delete: removes profile directory" {
  bash "$AGY_SWITCH" save other
  run bash "$AGY_SWITCH" delete other
  [ "$status" -eq 0 ]
  [ ! -d "$AGY_DIR/profiles/other" ]
}

@test "delete: cannot delete active profile" {
  run bash "$AGY_SWITCH" delete default
  [ "$status" -eq 1 ]
  [[ "$output" == *"Cannot delete"* ]] || [[ "$output" == *"active"* ]]
}

@test "delete: nonexistent profile exits 1" {
  run bash "$AGY_SWITCH" delete nonexistent
  [ "$status" -eq 1 ]
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `bats tests/test_list_current_delete.bats`
Expected: FAIL on no-profiles message (current output is empty line, not "no profiles") and list asterisk format test

- [ ] **Step 3: Fix `cmd_list` — ensure empty profiles dir prints "no profiles"**

The current guard is `if [[ "$found" == false ]]; then echo "  (no profiles saved yet)"`. The test checks `*"no profiles"*` — this matches. Confirm by running manually against empty dir.

- [ ] **Step 4: Run to verify all pass**

Run: `bats tests/test_list_current_delete.bats`
Expected: PASS 8/8

- [ ] **Step 5: Commit**

```bash
git add tests/test_list_current_delete.bats
git commit -m "test: add bats tests for list, current, delete commands"
```

---

### Task 6: Full suite run + README test section

**Files:**
- Modify: `README.md` (add Testing section)
- Modify: `.gitignore` (ensure `tests/tmp/` excluded if any tmpfiles land there)

**Interfaces:**
- Consumes: all test files from Tasks 1–5
- Produces: `bats tests/` exits 0; README documents how to run tests

- [ ] **Step 1: Run the full suite as the gate**

Run: `bats tests/`
Expected: all tests PASS (count ≥ 23)

- [ ] **Step 2: If any tests fail, fix the script — not the test**

Use `bats tests/ --tap` output to identify which test and which assertion fails. Fix the minimum in `agy-switch` to make it pass.

- [ ] **Step 3: Add Testing section to README.md**

After the Installation section, add:

```markdown
## Running the Tests

The test suite uses [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

**Install bats:**
\`\`\`bash
sudo apt-get install bats          # Debian/Ubuntu
brew install bats-core             # macOS
\`\`\`

**Run all tests:**
\`\`\`bash
bats tests/
\`\`\`

Tests run against a temporary fake AGY directory — no real credentials are touched.
```

- [ ] **Step 4: Run full suite one final time to confirm green**

Run: `bats tests/`
Expected: all PASS

- [ ] **Step 5: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: add Testing section to README; run full bats suite green"
```
