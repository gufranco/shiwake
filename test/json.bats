#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

bats_require_minimum_version 1.5.0

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/sw-json.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  mkdir -p "${TARGET}"
}

teardown() {
  rm -rf "${WORK}"
}

@test "--json prints the result of a sort as one JSON object" {
  # Arrange
  sw_test_files "${TARGET}" apple Avocado banana Cherry
  local expected="{\"folder\":\"${TARGET}\",\"dry_run\":false,\"files\":4,\"moved\":4,\"kept\":0,\"failed\":0,\"folders\":{\"A\":2,\"B\":1,\"C\":1}}"

  # Act
  run sw_test_run --json "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
  [[ -f "${TARGET}/A/apple" ]]
}

@test "--json with --dry-run reports the moves and moves nothing" {
  # Arrange
  sw_test_files "${TARGET}" apple 2048.txt
  local expected="{\"folder\":\"${TARGET}\",\"dry_run\":true,\"files\":2,\"moved\":2,\"kept\":0,\"failed\":0,\"folders\":{\"#\":1,\"A\":1}}"

  # Act
  run sw_test_run --dry-run --json "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
  [[ -f "${TARGET}/apple" ]]
}

@test "--json on a folder with nothing to sort reports zero files" {
  # Arrange
  local expected="{\"folder\":\"${TARGET}\",\"dry_run\":false,\"files\":0,\"moved\":0,\"kept\":0,\"failed\":0,\"folders\":{}}"

  # Act
  run sw_test_run --json "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "--json counts a file kept beside one of the same name and warns on stderr" {
  # Arrange
  sw_test_files "${TARGET}" apple
  sw_test_files "${TARGET}/A" apple
  local expected="{\"folder\":\"${TARGET}\",\"dry_run\":false,\"files\":1,\"moved\":0,\"kept\":1,\"failed\":0,\"folders\":{}}"

  # Act
  run --separate-stderr sw_test_run --json "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
  [[ "${stderr}" == "shiwake: warning: A/apple already exists, so apple stays where it is." ]]
}

@test "--json escapes quotes, backslashes and control characters in the folder name" {
  # Arrange
  local odd
  odd="${WORK}/$(printf 'say "hi"\\now\tthen')"
  mkdir -p "${odd}"
  sw_test_files "${odd}" apple
  local expected="{\"folder\":\"${WORK}/say \\\"hi\\\"\\\\now\\u0009then\",\"dry_run\":false,\"files\":1,\"moved\":1,\"kept\":0,\"failed\":0,\"folders\":{\"A\":1}}"

  # Act
  run sw_test_run --json "${odd}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}
