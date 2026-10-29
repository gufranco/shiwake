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
  printf '\n'
  sw_say 8 "Folder: ${SW_DIR}"
  printf 'Plan:   %s into %s named for their first letter\n' "${sw_su_files}" "${sw_su_folders}"
  if [ "${SW_DRY_RUN}" = yes ]; then
    printf '        dry run: list each move and change nothing\n'
  fi
  printf '\n'
}

sw_report_json() {
  sw_rj_folders="$(printf '%s' "${SW_TALLY}" | tr ' ' '\n' | awk -F: '
    NF == 2 { if (!($1 in sum)) { order[++n] = $1 }; sum[$1] += $2 }
    END {
      printf "{"
      for (i = 1; i <= n; i++) { printf "%s\"%s\":%d", (i > 1 ? "," : ""), order[i], sum[order[i]] }
      printf "}"
    }')"
  sw_rj_dry=false
  [ "${SW_DRY_RUN}" = no ] || sw_rj_dry=true
  sw_rj_folder="$(sw_json_string "${SW_DIR}")"
  printf '{"folder":%s,"dry_run":%s,"files":%s,"moved":%s,"kept":%s,"failed":%s,"folders":%s}\n' \
    "${sw_rj_folder}" "${sw_rj_dry}" "${SW_FOUND}" "${SW_MOVED}" "${SW_KEPT}" "${SW_FAILED}" "${sw_rj_folders}"
  [ "${SW_FAILED}" -eq 0 ]
}

sw_report() {
  if [ "${SW_JSON}" = yes ]; then
    sw_report_json
    return
  fi
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
    [ "${SW_JSON}" = no ] || sw_report_json
    [ "${SW_JSON}" = yes ] || sw_say 0 "Nothing to sort in ${SW_DIR}."
    return 0
  fi
  [ "${SW_JSON}" = yes ] || sw_summary
  sw_st_mode=move
  [ "${SW_DRY_RUN}" = no ] || sw_st_mode=show
  sw_scan "${sw_st_mode}"
  sw_report
}
