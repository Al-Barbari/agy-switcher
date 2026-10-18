#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; }
teardown() { teardown_fake_agy_dir; }

@test "helpers: setup creates AGY_DIR with token file" {
  [ -f "$AGY_DIR/antigravity-oauth-token" ]
  [ -f "$AGY_DIR/settings.json" ]
}
