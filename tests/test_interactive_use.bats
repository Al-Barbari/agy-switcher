#!/usr/bin/env bats
load helpers

setup()    { setup_fake_agy_dir; bash "$AGY_SWITCH" init; }
teardown() { teardown_fake_agy_dir; }

@test "use interactive: selects profile by number via stdin" {
  bash "$AGY_SWITCH" save personal
  # Active is default. Profiles are: default, personal.
  # Send "2" via stdin to select the second profile:
  run bash -c "echo '2' | bash '$AGY_SWITCH' use"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Switched to profile" ]]
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "personal" ]
}

@test "use interactive: selects profile by name via stdin" {
  bash "$AGY_SWITCH" save personal
  run bash -c "echo 'personal' | bash '$AGY_SWITCH' use"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Switched to profile 'personal'" ]]
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "personal" ]
}

@test "use interactive: cancels cleanly on 'q'" {
  bash "$AGY_SWITCH" save personal
  run bash -c "echo 'q' | bash '$AGY_SWITCH' use"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cancelled" ]]
  [ "$(cat "$AGY_DIR/.agy-current-profile")" = "default" ]
}
