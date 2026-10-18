#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "rename: renames inactive profile directory" {
  bash "$AGY_SWITCH" save personal
  run bash "$AGY_SWITCH" rename personal personal-backup
  [ "$status" -eq 0 ]
  [ ! -d "$AGY_DIR/profiles/personal" ]
  [ -d "$AGY_DIR/profiles/personal-backup" ]
  [ -f "$AGY_DIR/profiles/personal-backup/antigravity-oauth-token" ]
}

@test "rename: renames active profile directory and updates .agy-current-profile" {
  run bash "$AGY_SWITCH" rename default primary
  [ "$status" -eq 0 ]
  [ ! -d "$AGY_DIR/profiles/default" ]
  [ -d "$AGY_DIR/profiles/primary" ]
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "primary" ]
}

@test "rename: fails if old profile does not exist" {
  run bash "$AGY_SWITCH" rename nonexistent newname
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}

@test "rename: fails if new name already exists" {
  bash "$AGY_SWITCH" save personal
  run bash "$AGY_SWITCH" rename default personal
  [ "$status" -eq 1 ]
  [[ "$output" =~ "already exists" ]]
}

@test "rename: fails if new name is a reserved keyword" {
  run bash "$AGY_SWITCH" rename default settings
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reserved" ]]
}

@test "rename: fails if new name has invalid characters" {
  run bash "$AGY_SWITCH" rename default "bad name!"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "invalid" ]]
}

@test "rename: fails if missing arguments" {
  run bash "$AGY_SWITCH" rename
  [ "$status" -eq 1 ]
  run bash "$AGY_SWITCH" rename onlyone
  [ "$status" -eq 1 ]
}
