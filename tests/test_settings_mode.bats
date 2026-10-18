#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "settings: default mode is per-profile" {
  run bash "$AGY_SWITCH" settings
  [ "$status" -eq 0 ]
  [[ "$output" =~ "per-profile" ]]
}

@test "settings: can set mode to shared" {
  run bash "$AGY_SWITCH" settings shared
  [ "$status" -eq 0 ]
  [[ "$output" =~ "shared" ]]

  run bash "$AGY_SWITCH" settings
  [ "$status" -eq 0 ]
  [[ "$output" =~ "shared" ]]
}

@test "settings: can set mode back to per-profile" {
  bash "$AGY_SWITCH" settings shared
  run bash "$AGY_SWITCH" settings per-profile
  [ "$status" -eq 0 ]
  [[ "$output" =~ "per-profile" ]]
}

@test "settings: rejects invalid mode" {
  run bash "$AGY_SWITCH" settings invalid-mode
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Invalid settings mode" ]]
}

@test "use in shared mode: does not overwrite settings.json" {
  # In shared mode, settings.json should NOT be replaced when switching profiles
  bash "$AGY_SWITCH" save personal
  bash "$AGY_SWITCH" settings shared

  echo '{"model":"MySharedModel"}' > "$AGY_DIR/settings.json"
  run bash "$AGY_SWITCH" use personal
  [ "$status" -eq 0 ]

  run grep "MySharedModel" "$AGY_DIR/settings.json"
  [ "$status" -eq 0 ]
}

@test "use in per-profile mode: auto-saves active profile settings before switching" {
  # In per-profile mode, modifying active settings.json before switching to another profile
  # should auto-save those changes to the active profile's directory
  bash "$AGY_SWITCH" save personal
  bash "$AGY_SWITCH" settings per-profile

  # Currently on 'default'. Modify active settings.json:
  echo '{"model":"ModifiedDefaultModel"}' > "$AGY_DIR/settings.json"

  # Switch to 'personal'
  bash "$AGY_SWITCH" use personal

  # Switch back to 'default'
  bash "$AGY_SWITCH" use default

  # Verify the modified setting was auto-saved and restored
  run grep "ModifiedDefaultModel" "$AGY_DIR/settings.json"
  [ "$status" -eq 0 ]
}

@test "use in per-profile mode: does NOT overwrite previous profile's token" {
  # In per-profile mode, modifying active token file before switching
  # should NOT overwrite the previous profile's saved token on disk
  bash "$AGY_SWITCH" save personal
  bash "$AGY_SWITCH" settings per-profile

  local original_default_token
  original_default_token="$(cat "$AGY_DIR/profiles/default/antigravity-oauth-token")"

  # Currently on 'default'. Modify active token:
  echo "rogue-token-modified" > "$AGY_DIR/antigravity-oauth-token"

  # Switch to 'personal'
  bash "$AGY_SWITCH" use personal

  # Verify 'default' saved token on disk was NOT overwritten by the modified token
  local saved_default_token
  saved_default_token="$(cat "$AGY_DIR/profiles/default/antigravity-oauth-token")"
  [ "$saved_default_token" = "$original_default_token" ]
  [ "$saved_default_token" != "rogue-token-modified" ]
}

@test "settings: corrupt or empty mode file defaults to per-profile" {
  echo "corrupt-mode" > "$AGY_DIR/.agy-settings-mode"
  run bash "$AGY_SWITCH" settings
  [ "$status" -eq 0 ]
  [[ "$output" =~ "per-profile" ]]

  : > "$AGY_DIR/.agy-settings-mode"
  run bash "$AGY_SWITCH" settings
  [ "$status" -eq 0 ]
  [[ "$output" =~ "per-profile" ]]
}
