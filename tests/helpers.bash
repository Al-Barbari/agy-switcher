# tests/helpers.bash
# Exports AGY_DIR pointing to a temp dir with fake credentials.

setup_fake_agy_dir() {
  export AGY_DIR
  AGY_DIR="$(mktemp -d)"
  cp "$BATS_TEST_DIRNAME/fixtures/fake-token.json" \
     "$AGY_DIR/antigravity-oauth-token"
  cp "$BATS_TEST_DIRNAME/fixtures/fake-settings.json" \
     "$AGY_DIR/settings.json"
}

teardown_fake_agy_dir() {
  rm -rf "$AGY_DIR"
}

# Path to the script under test
AGY_SWITCH="$BATS_TEST_DIRNAME/../agy-switch"
