#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/sw-cli.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  sw_test_files "${TARGET}" apple
}

teardown() {
  chmod -R u+rwx "${WORK}"
  rm -rf "${WORK}"
}

from_folder() {
  local dir="$1"
  shift
  (cd "${dir}" && "$@")
}

@test "help prints the usage page" {
  # Arrange
  local first="shiwake - sort the files of a folder into A to Z subfolders by their first letter"

  # Act
  run sw_test_run help

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "${first}" ]]
}

@test "-h and --help print the same page as help" {
  # Arrange
  local page
  page="$(sw_test_run help)"

  # Act
  run sw_test_run -h

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${page}" ]]
  [[ "$(sw_test_run --help || true)" == "${page}" ]]
}

@test "version prints the program, its version and the platform" {
  # Arrange
  local platform
  platform="$(uname -sr)"

  # Act
  run sw_test_run --version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^shiwake\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
  [[ "${lines[1]}" == "platform: ${platform}" ]]
}

@test "version and -V print the same lines" {
  # Arrange
  local expected
  expected="$(sw_test_run --version)"

  # Act
  run sw_test_run version

  # Assert
  [[ "${output}" == "${expected}" ]]
  [[ "$(sw_test_run -V || true)" == "${expected}" ]]
}

@test "version reports an unknown platform when uname fails" {
  # Arrange
  sw_test_shim uname "exit 1"

  # Act
  run sw_test_run --version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "platform: unknown" ]]
}

@test "doctor lists mkdir and mv with their paths" {
  # Arrange
  local mv_path
  mv_path="$(command -v mv)"

  # Act
  run sw_test_run doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "mkdir              ok       "* ]]
  [[ "${lines[1]}" == "mv                 ok       ${mv_path}, "* ]]
}

@test "doctor fails and names a missing mv" {
  # Arrange
  local farm
  farm="$(sw_test_farm mv)"

  # Act
  run sw_test_run_path "${farm}" doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"mv                 missing  required, part of coreutils"* ]]
}

@test "the tool runs by its bare name from inside its own folder" {
  # Arrange
  local -a shell_words
  read -r -a shell_words <<<"${SW_SHELL:-sh}"
  cd "${REPO_DIR}/bin" || return 1

  # Act
  PATH="${REPO_DIR}/bin:${PATH}" run "${shell_words[@]}" shiwake version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^shiwake\ [0-9] ]]
}

@test "an unknown option is named with a hint" {
  # Arrange
  local expected="shiwake: unknown option '--fast'. run 'shiwake help' for usage."

  # Act
  run sw_test_run --fast "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "an unknown short option is named with a hint" {
  # Arrange
  local expected="shiwake: unknown option '-n'. run 'shiwake help' for usage."

  # Act
  run sw_test_run -n "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "a value given to --dry-run is refused" {
  # Arrange
  local expected="shiwake: unknown option '--dry-run'. run 'shiwake help' for usage."

  # Act
  run sw_test_run --dry-run=yes "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "a second folder is refused" {
  # Arrange
  local expected="shiwake: unexpected extra argument 'more'. run 'shiwake help' for usage."

  # Act
  run sw_test_run "${TARGET}" more

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "an empty folder name is refused" {
  # Arrange
  local expected="shiwake: the folder name is empty. run 'shiwake help' for usage."

  # Act
  run sw_test_run ""

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "-- ends the options so a folder may start with a dash" {
  # Arrange
  sw_test_files "${WORK}/-sorted" melon

  # Act
  run sw_test_run --dry-run -- "${WORK}/-sorted"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"melon -> M/"* ]]
}

@test "a folder named like a command is reached by its path" {
  # Arrange
  sw_test_files "${WORK}/help" kiwi

  # Act
  run sw_test_run --dry-run "${WORK}/help"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"kiwi -> K/"* ]]
}

@test "a missing folder is an error" {
  # Arrange
  local missing="${WORK}/nowhere"

  # Act
  run sw_test_run "${missing}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "shiwake: no such folder: ${missing}" ]]
}

@test "a file given as the folder is an error" {
  # Arrange
  local file="${TARGET}/apple"

  # Act
  run sw_test_run "${file}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "shiwake: not a folder: ${file}" ]]
}

@test "a folder that cannot be entered is an error" {
  # Arrange
  [[ "$(id -u || true)" -ne 0 ]] || skip "root enters every folder"
  mkdir "${WORK}/locked"
  chmod 000 "${WORK}/locked"

  # Act
  run sw_test_run "${WORK}/locked"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "shiwake: cannot open the folder: ${WORK}/locked" ]]
}

@test "without a folder and a terminal the current folder is sorted" {
  # Arrange
  local expected="Folder: ${TARGET}"

  # Act
  run from_folder "${TARGET}" sw_test_run --dry-run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${expected}"* ]]
}

@test "in a terminal the folder is asked for" {
  # Arrange
  local answer="${TARGET}"

  # Act
  SW_INTERACTIVE=1 run sw_test_run --dry-run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Folder to sort ["*"]: "* ]]
  [[ "${output}" == *"apple -> A/"* ]]
}

@test "Enter at the prompt sorts the current folder" {
  # Arrange
  local answer=""

  # Act
  SW_INTERACTIVE=1 run from_folder "${TARGET}" sw_test_run --dry-run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Folder to sort [${TARGET}]: "* ]]
  [[ "${output}" == *"Folder: ${TARGET}"* ]]
}

@test "a folder typed with a tilde starts at home" {
  # Arrange
  # shellcheck disable=SC2088
  local answer="~/target"

  # Act
  SW_INTERACTIVE=1 HOME="${WORK}" run sw_test_run --dry-run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Folder: ${TARGET}"* ]]
}

@test "a lone tilde is home itself" {
  # Arrange
  local answer="~"

  # Act
  SW_INTERACTIVE=1 HOME="${TARGET}" run sw_test_run --dry-run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Folder: ${TARGET}"* ]]
}

@test "end of input at the prompt stops the run" {
  # Arrange
  local empty=""

  # Act
  SW_INTERACTIVE=1 run sw_test_run < <(printf '%s' "${empty}")

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "Folder to sort ["*"]: " ]]
}

help_options() {
  local page
  page="$(sw_test_run help)" || return 1
  awk '/^  --/ { for (i = 1; i <= NF; i++) if (match($i, /^--[a-z0-9][a-z0-9-]*/)) { name = substr($i, RSTART, RLENGTH); if (!seen[name]++) print name } }' <<<"${page}"
}

option_drift() {
  local option name man_form missing="" listed completed
  listed="$(help_options)" || return 1
  completed="$(grep -oE -- "--[a-z0-9][a-z0-9-]*" "${REPO_DIR}/completions/shiwake.bash")" || return 1
  for option in ${listed}; do
    name="${option#--}"
    man_form="\\-\\-${name//-/\\-}"
    grep -qF -- "${man_form}" "${REPO_DIR}/man/shiwake.1" || missing="${missing} man:${option}"
    grep -qE -- "(^|[ \"])${option}( |\"|$)" "${REPO_DIR}/completions/shiwake.bash" || missing="${missing} bash:${option}"
    grep -qE -- "[')]${option}\\[" "${REPO_DIR}/completions/_shiwake" || missing="${missing} zsh:${option}"
    grep -qE -- "-l ${name} " "${REPO_DIR}/completions/shiwake.fish" || missing="${missing} fish:${option}"
  done
  for option in ${completed}; do
    grep -qx -- "${option}" <<<"${listed}" || missing="${missing} help:${option}"
  done
  printf '%s' "${missing}"
}

@test "help, man page and completions list the same options" {
  # Arrange
  local expected=""

  # Act
  run option_drift

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "the man page passes mandoc lint" {
  # Arrange
  local page="${REPO_DIR}/man/shiwake.1"

  # Act
  run mandoc -T lint "${page}"

  # Assert
  [[ "${status}" -eq 0 ]]
}
