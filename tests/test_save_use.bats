#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "save: creates named profile directory" {
  run bash "$AGY_SWITCH" save personal
  [ "$status" -eq 0 ]
  [ -d "$AGY_DIR/profiles/personal" ]
}

@test "save: copies token into named profile" {
  run bash "$AGY_SWITCH" save personal
  [ "$status" -eq 0 ]
  [ -f "$AGY_DIR/profiles/personal/antigravity-oauth-token" ]
}

@test "save: rejects name with spaces" {
  run bash "$AGY_SWITCH" save "bad name"
  [ "$status" -eq 1 ]
}

@test "save: rejects name with special chars" {
  run bash "$AGY_SWITCH" save "bad!"
  [ "$status" -eq 1 ]
}

@test "save: fails with no token file" {
  rm "$AGY_DIR/antigravity-oauth-token"
  run bash "$AGY_SWITCH" save work
  [ "$status" -eq 1 ]
}

@test "use: switches active profile" {
  bash "$AGY_SWITCH" save personal
  run bash "$AGY_SWITCH" use personal
  [ "$status" -eq 0 ]
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "personal" ]
}

@test "use: overwrites active token file with profile token" {
  bash "$AGY_SWITCH" save personal
  echo "old-token" > "$AGY_DIR/antigravity-oauth-token"
  bash "$AGY_SWITCH" use personal
  run grep "fake-access" "$AGY_DIR/antigravity-oauth-token"
  [ "$status" -eq 0 ]
}

@test "use: already-active profile exits 0 with warning" {
  run bash "$AGY_SWITCH" use default
  [ "$status" -eq 0 ]
  [[ "$output" == *"already active"* ]]
}

@test "use: nonexistent profile exits 1" {
  run bash "$AGY_SWITCH" use nonexistent
  [ "$status" -eq 1 ]
}
