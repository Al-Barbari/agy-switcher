# agy-switch

**Switch between multiple Google Antigravity (AGY) accounts on a single machine.**

`agy-switch` is a small shell script that saves named snapshots ("profiles") of your AGY credentials and settings, so you can jump between accounts — personal, work, client — with a single command.

```
agy-switch use personal   # → switch to personal account
agy                       # → runs as your personal Google account

agy-switch use default    # → switch back to work
agy                       # → runs as your work account
```

---

## Table of Contents

- [How It Works](#how-it-works)
- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [Adding a Second Account](#adding-a-second-account)
- [Commands](#commands)
  - [agy-switch init](#agy-switch-init)
  - [agy-switch list](#agy-switch-list)
  - [agy-switch add <name>](#agy-switch-add-name)
  - [agy-switch save <name>](#agy-switch-save-name)
  - [agy-switch use [name]](#agy-switch-use-name)
  - [agy-switch rename <old> <new>](#agy-switch-rename-old-new)
  - [agy-switch settings [per-profile|shared]](#agy-switch-settings-per-profileshared)
  - [agy-switch current](#agy-switch-current)
  - [agy-switch delete <name>](#agy-switch-delete-name)
  - [agy-switch help](#agy-switch-help)
- [Settings Modes: Per-Profile vs Shared](#settings-modes-per-profile-vs-shared)
- [Workflow Examples](#workflow-examples)
- [What Gets Saved Per Profile](#what-gets-saved-per-profile)
- [Security Notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Running the Tests](#running-the-tests)
- [Uninstall](#uninstall)

---

## How It Works

AGY stores your active credentials in two files:

| File | Purpose |
|------|---------|
| `~/.gemini/antigravity-cli/antigravity-oauth-token` | OAuth token (access token, refresh token, ID token) |
| `~/.gemini/antigravity-cli/settings.json` | Preferences: model, mode, trusted workspaces, etc. |

`agy-switch` keeps a copy of both files for each named profile under:

```
~/.gemini/antigravity-cli/profiles/
├── default/
│   ├── antigravity-oauth-token   ← your work account credentials
│   └── settings.json             ← your work settings
└── personal/
    ├── antigravity-oauth-token   ← your personal account credentials
    └── settings.json             ← your personal settings
```

Switching copies the chosen profile's files over the active ones — AGY reads them on the next `agy` invocation.

---

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/agy-switcher.git ~/agy-switcher
```

Or if you already have the folder:

```bash
ls ~/agy-switcher/agy-switch   # should be there
```

### 2. Make the script executable

```bash
chmod +x ~/agy-switcher/agy-switch
```

### 3. Add it to your PATH

The easiest approach is a symlink into `~/.local/bin` (already on PATH for most Linux setups):

```bash
ln -sf ~/agy-switcher/agy-switch ~/.local/bin/agy-switch
```

Verify it works:

```bash
agy-switch help
```

> **Alternative — add the project directory to your PATH directly** by adding this to your `~/.bashrc` or `~/.zshrc`:
> ```bash
> export PATH="$HOME/agy-switcher:$PATH"
> ```
> Then `source ~/.bashrc` (or restart your terminal).

---

## First-Time Setup

Run `init` once. It snapshots your **currently active** AGY account as a profile named `default`:

```bash
agy-switch init
```

**Expected output:**
```
✓  Saved current account as profile 'default'

Initialized! Current account saved as profile 'default'.

  To add a second account:
    1.  Run 'agy' and follow the auth prompts to log in
    2.  Exit agy (Ctrl+D Ctrl+D)
    3.  Run:  agy-switch save <profile-name>
    4.  Run:  agy-switch use default  (to switch back)
```

> **Important:** `init` requires that you already have an active AGY session. If you haven't authenticated yet, run `agy` first and complete the login flow.

---

## Adding a Second Account

Follow these steps every time you want to add a new account:

> **Tip:** You can also run `agy-switch add <name>` (e.g. `agy-switch add personal`) for guided step-by-step instructions directly in your terminal.

### Step 1 — Make sure your first account is saved

```bash
agy-switch init         # (skip if you already ran this)
agy-switch list         # confirm 'default' is listed
```

### Step 2 — Log in with the second account

Launch AGY — it will prompt you to authenticate. When it opens the browser, **use the new Google account** (e.g., your personal Gmail):

```bash
agy
```

Complete the browser authentication flow. Once you're inside the `agy` TUI, type `/exit` or press `Ctrl+D Ctrl+D` to exit.

### Step 3 — Save the new account as a profile

```bash
agy-switch save personal
```

Give the profile any name you like: `personal`, `client1`, `freelance`, etc.

### Step 4 — Switch back to your original account

```bash
agy-switch use default
```

### Step 5 — Confirm both profiles exist

```bash
agy-switch list
```

Output:
```
AGY Profiles
──────────────────────────────────
  * default  (active)
    personal
```

---

## Commands

| Command | Description |
|---|---|
| [`agy-switch init`](#agy-switch-init) | First-time setup — snapshots active session as `default` |
| [`agy-switch list`](#agy-switch-list) | List all saved profiles (`*` marks active) |
| [`agy-switch add <name>`](#agy-switch-add-name) | Guide through adding a new account profile |
| [`agy-switch save <name>`](#agy-switch-save-name) | Snapshot current account session into a profile |
| [`agy-switch use [name]`](#agy-switch-use-name) | Switch profile by name, or display interactive menu if omitted |
| [`agy-switch rename <old> <new>`](#agy-switch-rename-old-new) | Rename a profile (updates active marker if active) |
| [`agy-switch settings [per-profile\|shared]`](#agy-switch-settings-per-profileshared) | View or set settings mode (`per-profile` or `shared`) |
| [`agy-switch current`](#agy-switch-current) | Print currently active profile name |
| [`agy-switch delete <name>`](#agy-switch-delete-name) | Delete an inactive profile |
| [`agy-switch help`](#agy-switch-help) | Show help and usage examples |

---

### `agy-switch init`

**First-time setup.** Saves the currently authenticated AGY account as a profile named `default` and marks it as active.

```bash
agy-switch init
```

> Safe to run multiple times — if profiles already exist, it lists them and exits without overwriting.

---

### `agy-switch list`

List all saved profiles. The currently active profile is marked with `*`.

```bash
agy-switch list
```

```
AGY Profiles
──────────────────────────────────
  * default  (active)
    personal
    client-acme
```

---

### `agy-switch add <name>`

Guided onboarding for new accounts. Validates that `<name>` is valid, non-reserved, and does not already exist, then displays step-by-step instructions to log into AGY and snapshot the new profile.

```bash
agy-switch add personal
```

```
Adding new profile: personal
──────────────────────────────────
  1. Run 'agy' in your terminal and complete the login prompts for this account.
  2. Once inside the agy session, exit with Ctrl+D Ctrl+D (or /exit).
  3. Save the account credentials as 'personal':
       agy-switch save personal
```

> **Naming rules:** Profile names can contain letters, numbers, hyphens, and underscores (`^[a-zA-Z0-9_-]+$`). Reserved command names (`init`, `list`, `save`, `use`, `current`, `delete`, `rename`, `add`, `settings`, `help`) cannot be used as profile names.

---

### `agy-switch save <name>`

Snapshot the **current** AGY session (token + settings) into a named profile. Creates the profile if it doesn't exist; **overwrites** if it does.

```bash
agy-switch save personal
agy-switch save client-acme
agy-switch save work-backup   # update an existing profile
```

> **Tip:** Profile names can contain letters, numbers, hyphens, and underscores. Spaces and reserved command names are not allowed.

---

### `agy-switch use [name]`

Activate a saved profile. You can provide a profile name directly or omit it to launch an interactive selection menu.

#### Direct switch
```bash
agy-switch use personal
agy-switch use default
```

```
✓  Switched to profile 'personal'
     Run 'agy' to start a session with this account.
```

#### Interactive switch (no argument)
Running `agy-switch use` with no argument displays a numbered interactive menu to pick from:

```bash
agy-switch use
```

```
Select an AGY profile to switch to:
  1) * default (active)
  2) personal
  3) client-acme

Enter number or profile name (or 'q' to cancel): 2
✓  Switched to profile 'personal'
     Run 'agy' to start a session with this account.
```

- Enter the menu number (e.g. `2`) or profile name (e.g. `personal`) to switch.
- Enter `q`, `Q`, or press Enter on an empty line to cancel without switching.

#### Settings behavior during switch
- In **`per-profile` mode** (default): changes made to your active `settings.json` (such as model, agent mode, or trusted workspaces) are **automatically saved** back to the current profile before swapping, and the target profile's settings are loaded.
- In **`shared` mode**: only credentials (`antigravity-oauth-token`) are swapped; `settings.json` is left untouched.

---

### `agy-switch rename <old> <new>`

Rename a saved profile from `<old>` to `<new>`.

```bash
agy-switch rename default work
agy-switch rename tmp client-acme
```

```
✓  Renamed profile 'default' to 'work'
```

- Validates that `<old>` exists and `<new>` is a valid, non-reserved name that does not already exist.
- Renames the profile directory under `~/.gemini/antigravity-cli/profiles/`.
- **Automatic active pointer update:** If the profile being renamed is currently active, the active profile pointer (`.agy-current-profile`) is automatically updated to `<new>`.

---

### `agy-switch settings [per-profile|shared]`

View or set the settings sharing mode.

```bash
# View the current settings mode
agy-switch settings

# Switch to per-profile mode (default)
agy-switch settings per-profile

# Switch to shared mode
agy-switch settings shared
```

#### Modes explained:
- **`per-profile` (default):**
  Each account retains its own active model, agent mode, and workspace list. Modifications to settings are auto-saved before switching to another profile.
- **`shared`:**
  Model, agent mode, and preferences in `settings.json` are shared globally across all accounts; only authentication credentials (`antigravity-oauth-token`) are swapped.

The setting is stored in `~/.gemini/antigravity-cli/.agy-settings-mode`. Defaults to `per-profile` if absent or empty.

---

### `agy-switch current`

Print the name of the currently active profile.

```bash
agy-switch current
```

```
Active profile: personal
```

---

### `agy-switch delete <name>`

Remove a saved profile. You **cannot delete the currently active profile** — switch to another one first.

```bash
agy-switch delete old-client
```

```
✓  Deleted profile 'old-client'
```

---

### `agy-switch help`

Print the help message with all commands and examples.

```bash
agy-switch help
agy-switch --help
agy-switch -h
```

---

## Settings Modes: Per-Profile vs Shared

`agy-switch` supports two modes for managing AGY preferences (`settings.json`):

| Feature | `per-profile` (Default) | `shared` |
|---|---|---|
| **OAuth Credentials** (`antigravity-oauth-token`) | Swapped per account | Swapped per account |
| **Model & Agent Mode** | Independent per account | Shared globally across all accounts |
| **Trusted Workspaces** | Independent list per account | Shared list across all accounts |
| **Auto-Save on Switch** | ✅ Auto-saves active profile's `settings.json` before switch | ❌ `settings.json` left untouched |
| **Config File** | `~/.gemini/antigravity-cli/.agy-settings-mode` (`per-profile`) | `~/.gemini/antigravity-cli/.agy-settings-mode` (`shared`) |

### When to use `per-profile`
Recommended for most users. Each account maintains its own isolated preferences:
- Work account: configured with enterprise models and corporate repositories in the trusted workspaces list.
- Personal account: configured with personal models or experimental modes and personal repository workspaces.
- Modifications made during your session are automatically saved back to the active profile on switch.

### When to use `shared`
Recommended if you want identical behavior regardless of which account is active:
- You want the same model selection, agent settings, and trusted workspace folders across all Google accounts.
- Switching accounts only swaps OAuth tokens for authentication and billing.

---

## Workflow Examples

### Daily workflow — switching between work and personal

```bash
# Morning: start with work account (already default)
agy-switch current          # → default

# Afternoon: switch to personal project
agy-switch use personal
agy                         # → runs as personal Gmail account
# ... do personal project work ...
# (exit agy)

# Back to work
agy-switch use default
agy
```

---

### Onboarding a client account

```bash
# 1. Save current state
agy-switch save default

# 2. Authenticate as the client
agy
# (log in with client Google account in browser, then exit)

# 3. Save the client profile
agy-switch save client-acme

# 4. Switch back
agy-switch use default
```

---

### Re-saving a profile after token refresh

OAuth tokens expire and get automatically refreshed while `agy` is running. After a long session with a profile you'd like to keep fresh:

```bash
# While 'personal' is active (agy-switch current → personal)
agy-switch save personal     # overwrites with the fresh token
```

---

### Switching profiles interactively

When you have multiple accounts and don't want to type the full name, run `agy-switch use` without arguments:

```bash
agy-switch use
# Select an AGY profile to switch to:
#   1) * default (active)
#   2) personal
#   3) client-acme
# Enter number or profile name (or 'q' to cancel): 2
```

---

### Renaming a profile

Rename profiles anytime without losing your active profile tracking:

```bash
# Rename 'default' to 'work'
agy-switch rename default work

# Confirm the active pointer updated
agy-switch current   # → work
```

---

### Configuring shared settings across accounts

If you prefer having identical models, system prompts, and workspaces across all accounts:

```bash
# Switch to shared mode
agy-switch settings shared

# Now switching accounts only changes OAuth tokens; settings.json stays untouched
agy-switch use personal
agy-switch use work

# Switch back to independent per-profile settings whenever desired
agy-switch settings per-profile
```

---

### Listing profiles in a script

```bash
#!/usr/bin/env bash
# Print all saved profile names (one per line, no decoration)
ls ~/.gemini/antigravity-cli/profiles/
```

---

## What Gets Saved Per Profile

| File | Included? | Notes |
|------|-----------|-------|
| `antigravity-oauth-token` | ✅ Yes | Full OAuth credentials: access token, refresh token, ID token |
| `settings.json` | ✅ Yes (per-profile mode) | Model selection, agent mode, trusted workspaces, tool permissions |

> **Settings Mode Behavior:**
> - In **`per-profile` mode (default)**: `settings.json` is saved and swapped per profile. When switching away from a profile, your current settings are **automatically saved** into that profile before the new profile's settings are loaded. Each account maintains its own independent model, agent mode, and trusted workspace list.
> - In **`shared` mode**: `settings.json` is preserved globally across all accounts. Switching profiles swaps only `antigravity-oauth-token` and leaves `settings.json` completely untouched.
>
> Check or toggle your mode anytime with `agy-switch settings [per-profile|shared]`.

---

## Security Notes

> **⚠️ Credentials are stored on disk in plaintext.** The `profiles/` directory contains real OAuth tokens. Protect it:

- The `.gitignore` in this repo **excludes `profiles/`** so credentials are never accidentally committed.
- Set restrictive permissions on the profiles directory:
  ```bash
  chmod 700 ~/.gemini/antigravity-cli/profiles
  ```
- **Never copy or share** a profile directory — it contains credentials that can be used to access your Google account.
- Profiles are stored at `~/.gemini/antigravity-cli/profiles/` — the same location where AGY already stores your active token, so there's no new attack surface beyond what AGY itself uses.

---

## Troubleshooting

### `✗ Profile 'X' not found`

The profile name doesn't exist. Check available profiles:

```bash
agy-switch list
```

### `✗ No active AGY token file found`

You need to authenticate with AGY before saving a profile:

```bash
agy    # follow the login prompts, then exit
agy-switch save <name>
```

### `✗ Cannot delete the currently active profile`

Switch to a different profile first:

```bash
agy-switch use default
agy-switch delete old-profile
```

### Token expired — getting auth errors in `agy`

The saved refresh token has expired (they last ~6 months). Re-authenticate:

```bash
# Remove the expired token so agy forces a re-login
rm ~/.gemini/antigravity-cli/antigravity-oauth-token
agy      # will prompt for auth
agy-switch save <profile-name>   # update the profile with fresh token
```

### Changes not taking effect

Make sure you exited the previous `agy` session before switching. AGY reads credentials at startup — a running session won't pick up the new token.

---

## Running the Tests

The test suite uses [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

**Install bats:**
```bash
sudo apt-get install -y bats       # Debian/Ubuntu
brew install bats-core             # macOS
```

**Run all tests:**
```bash
bats tests/
```

Tests execute against an isolated temporary directory using the `AGY_DIR` environment override — no real credentials or settings in `~/.gemini/antigravity-cli/` are ever modified or read during testing.

---

## Uninstall

```bash
# Remove the symlink
rm ~/.local/bin/agy-switch

# (Optional) Remove saved profiles — THIS DELETES ALL SAVED CREDENTIALS
rm -rf ~/.gemini/antigravity-cli/profiles
rm -f  ~/.gemini/antigravity-cli/.agy-current-profile

# Remove the project directory
rm -rf ~/agy-switcher
```

---

## License

MIT — do what you want with it.
