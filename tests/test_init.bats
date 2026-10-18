#!/usr/bin/env bats
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
  [ "$status" -eq 0 ]
  [ -f "$AGY_DIR/profiles/default/antigravity-oauth-token" ]
}

@test "init: writes default to current-profile marker" {
  run bash "$AGY_SWITCH" init
  [ "$status" -eq 0 ]
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
