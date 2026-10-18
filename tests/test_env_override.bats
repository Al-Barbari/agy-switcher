#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; }
teardown() { teardown_fake_agy_dir; }

@test "env: AGY_DIR override is respected for profiles dir" {
  run bash "$AGY_SWITCH" init
  [ "$status" -eq 0 ]
  [ -d "$AGY_DIR/profiles/default" ]
}
