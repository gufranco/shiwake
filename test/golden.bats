#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/sw-golden.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  mkdir -p "${TARGET}"
}

teardown() {
  rm -rf "${WORK}"
}

@test "a sort prints the same transcript as the recorded one" {
  # Arrange
  sw_test_files "${TARGET}" apple Avocado banana Cherry 2048.txt
  sw_test_files "${TARGET}/C" Cherry

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  sw_test_matches_golden sort "${output}"
}

@test "a dry run prints the same transcript as the recorded one" {
  # Arrange
  sw_test_files "${TARGET}" apple banana 2048.txt

  # Act
  run sw_test_run --dry-run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  sw_test_matches_golden dry-run "${output}"
}
