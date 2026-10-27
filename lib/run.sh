#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_choose_folder() {
  [ -z "${SW_DIR}" ] || return 0
  if ! sw_interactive; then
    SW_DIR=.
    return 0
  fi
  sw_cf_here="$(pwd -P)"
  SW_DIR="$(sw_prompt "Folder to sort" "${sw_cf_here}")" || return 1
}

sw_summary() {
  sw_su_files="$(sw_plural "${SW_FOUND}" file)"
  sw_su_folders="$(sw_plural "${SW_FOLDERS}" folder)"
  printf '\nFolder: %s\n' "${SW_DIR}"
  printf 'Plan:   %s into %s named for their first letter\n' "${sw_su_files}" "${sw_su_folders}"
  if [ "${SW_DRY_RUN}" = yes ]; then
    printf '        dry run: list each move and change nothing\n'
  fi
  printf '\n'
}

sw_report() {
  sw_re_folders="$(sw_plural "${SW_FILLED}" folder)"
  sw_re_count="$(sw_plural "${SW_FOUND}" file)"
  [ "${SW_MOVED}" -eq "${SW_FOUND}" ] || sw_re_count="${SW_MOVED} of ${sw_re_count}"
  if [ "${SW_DRY_RUN}" = yes ]; then
    printf 'Dry run: %s would move into %s. Nothing was moved.\n' "${sw_re_count}" "${sw_re_folders}"
  elif [ "${SW_MOVED}" -eq 0 ]; then
    printf 'Nothing was moved: every file stayed where it was.\n'
  else
    printf 'Sorted %s into %s.\n' "${sw_re_count}" "${sw_re_folders}"
  fi
  [ "${SW_FAILED}" -eq 0 ]
}

sw_start() {
  sw_args_parse "$@" || return 1
  sw_choose_folder || return 1
  sw_open_folder || return 1
  sw_scan tally
  if [ "${SW_FOUND}" -eq 0 ]; then
    printf 'Nothing to sort in %s.\n' "${SW_DIR}"
    return 0
  fi
  sw_summary
  sw_st_mode=move
  [ "${SW_DRY_RUN}" = no ] || sw_st_mode=show
  sw_scan "${sw_st_mode}"
  sw_report
}
