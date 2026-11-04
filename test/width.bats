#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d /tmp/sw-width.XXXXXX)"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  mkdir -p "${TARGET}"
}

teardown() {
  rm -rf "${WORK}"
}

widest_line() {
  awk '{ if (length($0) > widest) { widest = length($0) } } END { print widest + 0 }'
}

@test "help never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(sw_test_run help)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "version never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(sw_test_run version)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "an error stays on one line, however long" {
  # Arrange
  local message="a file named like one of the letter folders is in the way, so it stays where it is and the folder is left alone"

  # Act
  run sw_test_call sw_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "shiwake: ${message}" ]]
}

@test "a doctor row stays on one line, however long" {
  # Arrange
  local expected="mkdir              ok       /opt/homebrew/opt/uutils-coreutils/libexec/uubin/mkdir, uutils 0.12.0"

  # Act
  run sw_test_call sw_doctor_row "mkdir" ok "/opt/homebrew/opt/uutils-coreutils/libexec/uubin/mkdir, uutils 0.12.0"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "internal SW_ variables from the environment change nothing" {
  # Arrange
  sw_test_files "${TARGET}" apple banana

  # Act
  SW_DRY_RUN=yes SW_BATCH=0 run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Sorted 2 files into 2 folders."* ]]
  [[ -f "${TARGET}/A/apple" ]]
  [[ -f "${TARGET}/B/banana" ]]
}
