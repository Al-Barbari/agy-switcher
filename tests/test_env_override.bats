#!/usr/bin/env bats
load helpers

@test "env: AGY_DIR override is respected for profiles dir" {
  setup_fake_agy_dir
  run bash "$AGY_SWITCH" init
  [ -d "$AGY_DIR/profiles/default" ]
  teardown_fake_agy_dir
}
