#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "save: rejects reserved keyword 'settings'" {
  run bash "$AGY_SWITCH" save settings
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reserved" ]] || [[ "$output" =~ "invalid" ]]
}

@test "save: rejects reserved keyword 'init'" {
  run bash "$AGY_SWITCH" save init
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reserved" ]] || [[ "$output" =~ "invalid" ]]
}

@test "save: rejects reserved keyword 'help'" {
  run bash "$AGY_SWITCH" save help
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reserved" ]] || [[ "$output" =~ "invalid" ]]
}

@test "save: rejects reserved keyword 'rename'" {
  run bash "$AGY_SWITCH" save rename
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reserved" ]] || [[ "$output" =~ "invalid" ]]
}
