#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_usage() {
  cat <<'USAGE'
shiwake - sort the files of a folder into A to Z subfolders by first letter

usage:
  shiwake                      ask for the folder, then sort it
  shiwake [options] [folder]   move every file of the folder, the current one
                               when none is given, into a subfolder named for
                               its first letter
  shiwake doctor               check the tools shiwake needs
  shiwake version              print the version
  shiwake help                 print this page

options:
  --dry-run                    list every move and change nothing
  --json                       print the result as one JSON object, for scripts

notes:
  A file whose name starts with a letter goes into that letter's folder, A to
  Z, whatever its case. Any other first character, such as a digit, a symbol
  or an accented letter, sends it to the # folder. Symbolic links move like
  files. Subfolders, hidden files and special files stay where they are, and a
  file is never moved over one of the same name: it stays, and shiwake says
  so. Outside a terminal and without a folder, shiwake sorts the current one.
  -- ends the options, and a folder named help, doctor or version is sorted by
  giving its path, such as ./help.

examples:
  shiwake ~/Downloads
  shiwake --dry-run .
USAGE
}

sw_cli_hint() {
  sw_say 0 "${SW_PROG}: $1. run '${SW_PROG} help' for usage." >&2
}

sw_cli_version() {
  sw_version
  sw_cv_platform="$(uname -sr)" || sw_cv_platform="unknown"
  printf 'platform: %s\n' "${sw_cv_platform}"
}

sw_interactive() {
  [ "${SHIWAKE_INTERACTIVE:-}" = 1 ] && return 0
  [ -t 0 ]
}

sw_prompt() {
  printf '%s [%s]: ' "$1" "$2" >&2
  sw_pr_answer=""
  IFS= read -r sw_pr_answer || [ -n "${sw_pr_answer}" ] || return 1
  printf '%s\n' "${sw_pr_answer:-$2}"
}
