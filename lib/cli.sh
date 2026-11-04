#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_usage() {
  if sw_ui_out; then
    sw_usage_text | sw_ui_markdown | sw_gum format --theme "${SW_UI_HELP}"
    return 0
  fi
  sw_usage_text
}

sw_usage_text() {
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
  --theme NAME                 colours of the terminal interface, see notes

notes:
  A file whose name starts with a letter goes into that letter's folder, A to
  Z, whatever its case. Any other first character, such as a digit, a symbol
  or an accented letter, sends it to the # folder. Symbolic links move like
  files. Subfolders, hidden files and special files stay where they are, and a
  file is never moved over one of the same name: it stays, and shiwake says
  so. Outside a terminal and without a folder, shiwake sorts the current one.
  -- ends the options, and a folder named help, doctor or version is sorted by
  giving its path, such as ./help.

  On a terminal with gum installed, shiwake draws its prompts, summary and
  results with gum. --theme, else SHIWAKE_THEME, else KODOUGU_THEME picks the
  colours: kodougu, catppuccin-mocha, catppuccin-latte, dracula, nord,
  gruvbox, tokyo-night or mono. KODOUGU_ACCENT=#RRGGBB replaces only the
  accent, and NO_COLOR turns colour off.

examples:
  shiwake ~/Downloads
  shiwake --dry-run .
USAGE
}

sw_cli_hint() {
  sw_error "$1. run '${SW_PROG} help' for usage."
}

sw_cli_version() {
  sw_cv_platform="$(uname -sr)" || sw_cv_platform="unknown"
  if sw_ui_out; then
    sw_cv_text="$(sw_version)"
    sw_cv_badge="$(sw_ui_badge "${SW_UI_ACCENT}" "${sw_cv_text}")"
    sw_cv_chip="$(sw_ui_chip "platform ${sw_cv_platform}")"
    sw_gum join --horizontal "${sw_cv_badge}" " " "${sw_cv_chip}"
    return 0
  fi
  sw_version
  printf 'platform: %s\n' "${sw_cv_platform}"
}

sw_interactive() {
  [ "${SHIWAKE_INTERACTIVE:-}" = 1 ] && return 0
  [ -t 0 ]
}

sw_prompt() {
  if sw_ui_prompts; then
    sw_pd_answer="$(sw_ui_input "$1" "$2")" || return 1
    printf '%s\n' "${sw_pd_answer:-$2}"
    return 0
  fi
  printf '%s [%s]: ' "$1" "$2" >&2
  sw_pr_answer=""
  IFS= read -r sw_pr_answer || [ -n "${sw_pr_answer}" ] || return 1
  printf '%s\n' "${sw_pr_answer:-$2}"
}
