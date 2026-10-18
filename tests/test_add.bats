#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "add: fails if missing argument" {
  run bash "$AGY_SWITCH" add
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "add: fails if name is reserved keyword" {
  run bash "$AGY_SWITCH" add settings
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reserved" ]]
}

@test "add: fails if profile already exists" {
  run bash "$AGY_SWITCH" add default
  [ "$status" -eq 1 ]
  [[ "$output" =~ "already exists" ]]
}

@test "add: prints instructions for valid new profile" {
  run bash "$AGY_SWITCH" add client-acme
  [ "$status" -eq 0 ]
  [[ "$output" =~ "client-acme" ]]
  [[ "$output" =~ "save client-acme" ]]
}
