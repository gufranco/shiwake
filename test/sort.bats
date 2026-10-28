#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/sw-sort.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  mkdir -p "${TARGET}"
}

teardown() {
  rm -rf "${WORK}"
}

case_insensitive() {
  : >"${WORK}/probe"
  [[ -e "${WORK}/PROBE" ]]
}

@test "files go into a folder named for their first letter, whatever its case" {
  # Arrange
  sw_test_files "${TARGET}" apple Avocado banana Cherry
  local expected
  expected="$(printf '%s\n' ./A ./A/Avocado ./A/apple ./B ./B/banana ./C ./C/Cherry)"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(sw_test_tree "${TARGET}" || true)" == "${expected}" ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 4 files into 3 folders." ]]
}

@test "digits, symbols and accented letters go into the # folder" {
  # Arrange
  sw_test_files "${TARGET}" 2048.txt _draft '#tag' "$(printf '\303\251clair')" zebra
  local expected
  expected="$(printf '%s\n' ./# ./#/#tag ./#/2048.txt ./#/_draft "./#/$(printf '\303\251clair')" ./Z ./Z/zebra)"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(sw_test_tree "${TARGET}" || true)" == "${expected}" ]]
}

@test "the summary block names the folder and the plan before anything moves" {
  # Arrange
  sw_test_files "${TARGET}" apple banana
  local expected
  expected="$(printf '\nFolder: %s\nPlan:   2 files into 2 folders named for their first letter\n' "${TARGET}")"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}"$'\n\n'"Sorted 2 files into 2 folders." ]]
}

@test "one file and one folder are counted in the singular" {
  # Arrange
  sw_test_files "${TARGET}" apple

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Plan:   1 file into 1 folder named for their first letter"* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 1 file into 1 folder." ]]
}

@test "a relative folder is shown as its full path" {
  # Arrange
  sw_test_files "${TARGET}" apple

  # Act
  run bash -c 'cd "$1" && shift && PATH="$1" sh "$2" --dry-run target' _ "${WORK}" "${PATH}" "${REPO_DIR}/bin/shiwake"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Folder: ${TARGET}"* ]]
}

@test "hidden files, subfolders and special files stay where they are" {
  # Arrange
  sw_test_files "${TARGET}" .profile apple
  mkdir "${TARGET}/projects"
  mkfifo "${TARGET}/pipe"
  local expected
  expected="$(printf '%s\n' ./.profile ./A ./A/apple ./pipe ./projects)"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(sw_test_tree "${TARGET}" || true)" == "${expected}" ]]
  [[ "${output}" == *"Plan:   1 file into 1 folder"* ]]
}

@test "files join a letter folder that already exists" {
  # Arrange
  sw_test_files "${TARGET}/M" mango
  sw_test_files "${TARGET}" melon
  local expected
  expected="$(printf '%s\n' ./M ./M/mango ./M/melon)"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(sw_test_tree "${TARGET}" || true)" == "${expected}" ]]
}

@test "symbolic links move as links, even links to folders" {
  # Arrange
  sw_test_files "${WORK}" outside
  mkdir "${WORK}/elsewhere"
  ln -s "${WORK}/outside" "${TARGET}/link"
  ln -s "${WORK}/elsewhere" "${TARGET}/dirlink"
  ln -s "${WORK}/nothing" "${TARGET}/broken"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -L "${TARGET}/L/link" && "$(readlink "${TARGET}/L/link" || true)" == "${WORK}/outside" ]]
  [[ -L "${TARGET}/D/dirlink" && "$(readlink "${TARGET}/D/dirlink" || true)" == "${WORK}/elsewhere" ]]
  [[ -L "${TARGET}/B/broken" ]]
  [[ -f "${WORK}/outside" && -d "${WORK}/elsewhere" ]]
}

@test "names with spaces, newlines, dashes and glob characters move intact" {
  # Arrange
  local newline
  newline="$(printf 'line\nbreak')"
  sw_test_files "${TARGET}" "cherry pie" "-rf" "[a]b" "*star" "${newline}" "q?"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${TARGET}/C/cherry pie" ]]
  [[ -f "${TARGET}/#/-rf" && -f "${TARGET}/#/[a]b" && -f "${TARGET}/#/*star" ]]
  [[ -f "${TARGET}/L/${newline}" && -f "${TARGET}/Q/q?" ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 6 files into 4 folders." ]]
}

@test "a file named like an unmatched pattern goes only into the # folder" {
  # Arrange
  sw_test_files "${TARGET}" "[Zz]*"
  local expected
  expected="$(printf '%s\n' ./# './#/[Zz]*')"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(sw_test_tree "${TARGET}" || true)" == "${expected}" ]]
}

@test "a folder whose name holds glob characters is sorted literally" {
  # Arrange
  local odd="${WORK}/[ab]*"
  sw_test_files "${odd}" plum
  sw_test_files "${WORK}/a" peach

  # Act
  run sw_test_run "${odd}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${odd}/P/plum" && -f "${WORK}/a/peach" ]]
}

@test "a file is never moved over one of the same name" {
  # Arrange
  sw_test_files "${TARGET}/P" pear
  printf 'newer\n' >"${TARGET}/pear"
  sw_test_files "${TARGET}" plum

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(cat "${TARGET}/P/pear" || true)" == "pear" && "$(cat "${TARGET}/pear" || true)" == "newer" ]]
  [[ -f "${TARGET}/P/plum" ]]
  [[ "${output}" == *"shiwake: warning: P/pear already exists, so pear stays where it is."* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 1 of 2 files into 1 folder." ]]
}

@test "a run where every file already has a twin moves nothing" {
  # Arrange
  sw_test_files "${TARGET}/P" pear
  sw_test_files "${TARGET}" pear

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Nothing was moved: every file stayed where it was." ]]
}

@test "a file standing where a letter folder belongs keeps that letter's files in place" {
  # Arrange
  sw_test_files "${TARGET}" B banana apple

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/B" && -f "${TARGET}/banana" && -f "${TARGET}/A/apple" ]]
  [[ "${output}" == *"shiwake: B is not a folder, so the files that belong in it stay where they are."* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 1 of 3 files into 1 folder." ]]
}

@test "a link standing where a letter folder belongs is not followed" {
  # Arrange
  mkdir "${WORK}/elsewhere"
  ln -s "${WORK}/elsewhere" "${TARGET}/G"
  sw_test_files "${TARGET}" grape

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/grape" && ! -e "${WORK}/elsewhere/grape" ]]
}

@test "on a case-insensitive disk a one-letter file blocks its own folder" {
  # Arrange
  case_insensitive || skip "this disk tells upper and lower case apart"
  sw_test_files "${TARGET}" a

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/a" ]]
  [[ "${output}" == *"shiwake: A is not a folder"* ]]
}

@test "on a case-sensitive disk a one-letter file moves into its folder" {
  # Arrange
  ! case_insensitive || skip "this disk folds upper and lower case together"
  sw_test_files "${TARGET}" a

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${TARGET}/A/a" ]]
}

@test "a dry run lists every move and changes nothing" {
  # Arrange
  sw_test_files "${TARGET}" apple 9lives
  sw_test_files "${TARGET}/A" apple
  local before
  before="$(sw_test_tree "${TARGET}" || true)"

  # Act
  run sw_test_run --dry-run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(sw_test_tree "${TARGET}" || true)" == "${before}" ]]
  [[ "${output}" == *"        dry run: list each move and change nothing"* ]]
  [[ "${output}" == *"9lives -> #/"* ]]
  [[ "${output}" == *"shiwake: warning: A/apple already exists, so apple stays where it is."* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Dry run: 1 of 2 files would move into 1 folder. Nothing was moved." ]]
}

@test "a dry run reports a letter folder that is not a folder" {
  # Arrange
  sw_test_files "${TARGET}" K kiwi

  # Act
  run sw_test_run --dry-run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"shiwake: K is not a folder"* ]]
}

@test "a folder with nothing to sort says so" {
  # Arrange
  sw_test_files "${TARGET}" .hidden
  mkdir "${TARGET}/sub"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Nothing to sort in ${TARGET}." ]]
}

@test "a letter folder that cannot be created is reported with mkdir's words" {
  # Arrange
  sw_test_files "${TARGET}" apple
  sw_test_shim mkdir "printf 'mkdir: A: Permission denied\n' >&2; exit 1"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/apple" ]]
  [[ "${output}" == *"shiwake: could not create the folder A."* ]]
  [[ "${output}" == *"shiwake: mkdir said: mkdir: A: Permission denied"* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Nothing was moved: every file stayed where it was." ]]
}

@test "a move that fails part way counts what landed and what stayed" {
  # Arrange
  sw_test_files "${TARGET}" apple apricot avocado
  sw_test_shim mv "eval \"last=\\\${\$#}\"
\"\$REAL\" -- \"\$2\" \"\$last\"
printf 'mv: cannot move the rest\n' >&2
exit 1"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/A/apple" && -f "${TARGET}/apricot" && -f "${TARGET}/avocado" ]]
  [[ "${output}" == *"shiwake: mv said: mv: cannot move the rest"* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 1 of 3 files into 1 folder." ]]
}

@test "a move that lands nothing counts every file as stayed" {
  # Arrange
  sw_test_files "${TARGET}" apple
  sw_test_shim mv "printf 'mv: rename failed\n\n' >&2; exit 1"

  # Act
  run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ -f "${TARGET}/apple" ]]
  [[ "${output}" == *"shiwake: mv said: mv: rename failed"* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Nothing was moved: every file stayed where it was." ]]
}

@test "many files move in batches, one folder counted once" {
  # Arrange
  sw_test_files "${TARGET}" a1 a2 a3 a4 a5
  sw_test_shim mv "printf 'call\n' >>'${WORK}/mv.log'
exec \"\$REAL\" \"\$@\""

  # Act
  SHIWAKE_BATCH=2 run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "$(grep -c call "${WORK}/mv.log" || true)" == 3 ]]
  [[ "${output}" == *"Plan:   5 files into 1 folder named for their first letter"* ]]
  [[ "${lines[${#lines[@]} - 1]}" == "Sorted 5 files into 1 folder." ]]
}

@test "a blocked letter folder is reported once across batches" {
  # Arrange
  sw_test_files "${TARGET}" T t1 t2 t3 t4

  # Act
  SHIWAKE_BATCH=2 run sw_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "$(grep -c 'is not a folder' <<<"${output}" || true)" == 1 ]]
}
