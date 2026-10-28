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
  page="$(SHIWAKE_TERMINAL=1 sw_test_run help)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "version never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(SHIWAKE_TERMINAL=1 sw_test_run version)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "doctor never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(SHIWAKE_TERMINAL=1 sw_test_run doctor || true)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "an error longer than 80 columns wraps between words" {
  # Arrange
  local message="a file named like one of the letter folders is in the way, so it stays where it is and the folder is left alone"

  # Act
  SHIWAKE_TERMINAL=1 run sw_test_call sw_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "shiwake: a file named like one of the letter folders is in the way, so it stays" ]]
  [[ "${lines[1]}" == "where it is and the folder is left alone" ]]
}

@test "an error sent to a pipe stays on one line, however long" {
  # Arrange
  local message="a file named like one of the letter folders is in the way, so it stays where it is and the folder is left alone"

  # Act
  run sw_test_call sw_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "shiwake: ${message}" ]]
}

@test "a word wider than 80 columns stays whole on its own line" {
  # Arrange
  local folder="/Volumes/Archive/Scans/Every-Letter-Ever-Received-From-The-Family-1968-To-1985"

  # Act
  SHIWAKE_TERMINAL=1 run sw_test_call sw_say 8 "Folder: ${folder}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Folder:" ]]
  [[ "${lines[1]}" == "        ${folder}" ]]
}

@test "a doctor row too wide for 80 columns puts its detail on the next line" {
  # Arrange
  local found="/opt/homebrew/opt/uutils-coreutils/libexec/uubin/mkdir"

  # Act
  SHIWAKE_TERMINAL=1 run sw_test_call sw_doctor_row mkdir ok "${found}, uutils 0.12.0"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "mkdir              ok" ]]
  [[ "${lines[1]}" == "  ${found}, uutils 0.12.0" ]]
}

@test "a doctor row that fits in 80 columns stays on one line" {
  # Arrange
  local expected="mv                 ok       /bin/mv, bsd"

  # Act
  SHIWAKE_TERMINAL=1 run sw_test_call sw_doctor_row mv ok "/bin/mv, bsd"

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
