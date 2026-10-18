#!/usr/bin/env bats
load helpers

@test "helpers: setup creates AGY_DIR with token file" {
  setup_fake_agy_dir
  [ -f "$AGY_DIR/antigravity-oauth-token" ]
  teardown_fake_agy_dir
}
