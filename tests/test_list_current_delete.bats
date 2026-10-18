#!/usr/bin/env bats
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
  [ "$status" -eq 0 ]
  [[ "$output" == *"*"*"default"* ]]
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
