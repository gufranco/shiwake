#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/sw-ui.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  sw_test_files "${TARGET}" apple banana 1999
  export SHIWAKE_TEST_GUM=1
  export SHIWAKE_TEST_GUM_LOG="${WORK}/gum.log"
  export SHIWAKE_TEST_GUM_ANSWERS="${WORK}/answers"
  export SHIWAKE_INTERACTIVE=1
  unset KODOUGU_THEME KODOUGU_ACCENT SHIWAKE_THEME NO_COLOR
  : >"${SHIWAKE_TEST_GUM_LOG}"
}

teardown() {
  chmod -R u+rwx "${WORK}"
  rm -rf "${WORK}"
}

answers() {
  printf '%s\n' "$@" >"${SHIWAKE_TEST_GUM_ANSWERS}"
}

called() {
  grep -q -F -- "$1" "${SHIWAKE_TEST_GUM_LOG}"
}

@test "the folder is asked for under the header and sorted after a yes" {
  # Arrange
  answers "${TARGET}" "yes"

  # Act
  run sw_test_run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${TARGET}/A/apple" && -f "${TARGET}/B/banana" && -f "${TARGET}/#/1999" ]]
  [[ "${output}" == *"sort the files of a folder into A to Z subfolders"* ]]
  [[ "${output}" == *"Sorted 3 files into 3 folders."* ]]
  called "input --header Folder to sort"
  called "confirm Move 3 files into 3 folders?"
}

@test "an empty folder answer sorts the current folder" {
  # Arrange
  answers "" "yes"
  cd "${TARGET}"

  # Act
  run sw_test_run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${TARGET}/A/apple" && -f "${TARGET}/B/banana" ]]
  called "--placeholder ${TARGET}"
}

@test "a name already taken in its letter folder is drawn as a warning" {
  # Arrange
  mkdir -p "${TARGET}/A"
  printf 'kept' >"${TARGET}/A/apple"
  answers "yes"

  # Act
  run sw_test_run "${TARGET}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"WARN shiwake: A/apple already exists, so apple stays where it is."* ]]
  [[ -f "${TARGET}/apple" ]]
}

@test "a no at the confirmation moves nothing" {
  # Arrange
  answers "no"

  # Act
  run sw_test_run "${TARGET}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/apple" ]]
  [[ "${output}" == *"ERROR shiwake: stopped: nothing was moved."* ]]
}

@test "a dry run shows the summary and asks nothing" {
  # Arrange
  answers "<cancel>"

  # Act
  run sw_test_run --dry-run "${TARGET}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"dry run, nothing moves"* ]]
  [[ "${output}" == *"Dry run: 3 files would move into 3 folders. Nothing was moved."* ]]
  local log
  log="$(<"${SHIWAKE_TEST_GUM_LOG}")"
  [[ "${log}" != *"confirm"* ]]
}

@test "the result names how many files each folder got" {
  # Arrange
  answers "yes"

  # Act
  run sw_test_run "${TARGET}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"A 1"* ]]
  [[ "${output}" == *"# 1"* ]]
}

@test "a cancelled folder prompt stops the run" {
  # Arrange
  answers "<cancel>"

  # Act
  run sw_test_run </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "doctor draws its rows in a table" {
  # Arrange
  local expected="Ready. Every tool shiwake needs is here."

  # Act
  run sw_test_run doctor </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${expected}"* ]]
  [[ "${output}" == *"gum"* ]]
}

@test "doctor reports a missing mv below the table" {
  # Arrange
  local farm
  farm="$(sw_test_farm mv)"

  # Act
  run sw_test_run_path "${farm}" doctor </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"ERROR shiwake: a required tool is missing."* ]]
}

@test "doctor fails without gum" {
  # Arrange
  local farm
  farm="$(sw_test_farm gum)"

  # Act
  SHIWAKE_TEST_GUM=0 run sw_test_run_path "${farm}" doctor </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"gum                missing  install with: brew install gum"* ]]
}

@test "version shows the version and platform as badges" {
  # Arrange
  local version
  version="$(sed -n 's/^SHIWAKE_VERSION="\(.*\)"$/\1/p' "${REPO_DIR}/lib/core.sh")"

  # Act
  run sw_test_run version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "shiwake ${version} platform "* ]]
}

@test "help is formatted with gum" {
  # Arrange
  local expected="## Usage"

  # Act
  run sw_test_run help </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${expected}"* ]]
  called "format --theme pink"
}

@test "an unknown option is drawn as an error" {
  # Arrange
  local option="--nope"

  # Act
  run sw_test_run "${option}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "ERROR shiwake: unknown option '--nope'. run 'shiwake help' for usage." ]]
}

@test "--theme picks the palette over the environment" {
  # Arrange
  local theme="nord"

  # Act
  KODOUGU_THEME=dracula SHIWAKE_THEME=gruvbox run sw_test_run --theme "${theme}" version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #88C0D0"
}

@test "--theme= with a value picks the palette" {
  # Arrange
  local option="--theme=tokyo-night"

  # Act
  run sw_test_run "${option}" version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #7AA2F7"
}

@test "SHIWAKE_THEME overrides KODOUGU_THEME" {
  # Arrange
  local theme="catppuccin-latte"

  # Act
  KODOUGU_THEME=dracula SHIWAKE_THEME="${theme}" run sw_test_run version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #8839EF"
}

@test "an unknown theme stops before anything runs" {
  # Arrange
  local theme="solarized"

  # Act
  KODOUGU_THEME="${theme}" run sw_test_run "${TARGET}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"got: solarized"* ]]
  [[ -f "${TARGET}/apple" ]]
}

@test "--theme without a value stops with the usage hint" {
  # Arrange
  local option="--theme"

  # Act
  run sw_test_run version "${option}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"option '--theme' needs a value. run 'shiwake help' for usage."* ]]
}

@test "--theme after -- names a folder" {
  # Arrange
  mkdir -p "${WORK}/--theme"

  # Act
  run from_work sw_test_run --dry-run -- --theme </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Nothing to sort"* ]]
}

from_work() {
  (cd "${WORK}" && "$@")
}
