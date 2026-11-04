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
  if sw_ui_prompts; then
    sw_ui_header
  fi
  SW_DIR="$(sw_prompt "Folder to sort" "${sw_cf_here}")" || return 1
}

sw_summary() {
  sw_su_files="$(sw_plural "${SW_FOUND}" file)"
  sw_su_folders="$(sw_plural "${SW_FOLDERS}" folder)"
  if sw_ui_out; then
    sw_summary_drawn "${sw_su_files}" "${sw_su_folders}"
    return
  fi
  printf '\n'
  sw_say "Folder: ${SW_DIR}"
  printf 'Plan:   %s into %s named for their first letter\n' "${sw_su_files}" "${sw_su_folders}"
  if [ "${SW_DRY_RUN}" = yes ]; then
    printf '        dry run: list each move and change nothing\n'
  fi
  printf '\n'
}

sw_summary_drawn() {
  sw_sd2_mode="files move"
  [ "${SW_DRY_RUN}" = no ] || sw_sd2_mode="dry run, nothing moves"
  sw_ui_summary "Folder:" "${SW_DIR}" "Plan:" "$1 into $2 named for their first letter" "Mode:" "${sw_sd2_mode}"
  if [ "${SW_DRY_RUN}" = yes ] || ! sw_ui_prompts; then
    return 0
  fi
  if ! sw_ui_confirm "Move $1 into $2?" "Sort" "Stop"; then
    sw_error "stopped: nothing was moved."
    return 1
  fi
}

sw_report_drawn() {
  sw_rd_chips=""
  for sw_rd_pair in $(printf '%s' "${SW_TALLY}" | tr ' ' '\n' | awk -F: 'NF == 2 { if (!($1 in sum)) { order[++n] = $1 }; sum[$1] += $2 } END { for (i = 1; i <= n; i++) { print order[i] ":" sum[order[i]] } }'); do
    sw_rd_chip="$(sw_ui_chip "${sw_rd_pair%%:*} ${sw_rd_pair#*:}")"
    sw_rd_chips="$(sw_gum join --horizontal "${sw_rd_chips}" " " "${sw_rd_chip}")"
  done
  if [ -n "${sw_rd_chips}" ]; then
    printf '%s\n' "${sw_rd_chips}"
  fi
  sw_ui_done "$1"
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
    sw_re_line="Dry run: ${sw_re_count} would move into ${sw_re_folders}. Nothing was moved."
  elif [ "${SW_MOVED}" -eq 0 ]; then
    sw_re_line="Nothing was moved: every file stayed where it was."
  else
    sw_re_line="Sorted ${sw_re_count} into ${sw_re_folders}."
  fi
  if sw_ui_out; then
    sw_report_drawn "${sw_re_line}"
  else
    printf '%s\n' "${sw_re_line}"
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
    [ "${SW_JSON}" = yes ] || sw_say "Nothing to sort in ${SW_DIR}."
    return 0
  fi
  [ "${SW_JSON}" = yes ] || sw_summary || return 1
  sw_st_mode=move
  [ "${SW_DRY_RUN}" = no ] || sw_st_mode=show
  sw_scan "${sw_st_mode}"
  sw_report
}
