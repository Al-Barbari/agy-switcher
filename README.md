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

### `agy-switch save <name>`

Snapshot the **current** AGY session (token + settings) into a named profile. Creates the profile if it doesn't exist; **overwrites** if it does.

```bash
agy-switch save personal
agy-switch save client-acme
agy-switch save work-backup   # update an existing profile
```

> **Tip:** Profile names can contain letters, numbers, hyphens, and underscores. Spaces are not allowed.

---

### `agy-switch use <name>`

Activate a saved profile by copying its token and settings over the active files. The next `agy` session will run as this account.

```bash
agy-switch use personal
agy-switch use default
```

```
✓  Switched to profile 'personal'
     Run 'agy' to start a session with this account.
```

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
| `settings.json` | ✅ Yes | Model selection, agent mode, trusted workspaces, tool permissions |

> **Trusted workspaces** are stored in `settings.json`, so each profile has its own workspace trust list. When you switch profiles, your workspace paths switch with it.

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
