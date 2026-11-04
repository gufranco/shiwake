#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_doctor_row() {
  if sw_ui_out; then
    case "$2" in
    ok) sw_dw_state="@ok:ok" ;;
    *) sw_dw_state="@bad:$2" ;;
    esac
    SW_DOCTOR_ROWS="${SW_DOCTOR_ROWS}$1	${sw_dw_state}	$3
"
    return 0
  fi
  printf '%-18s %-8s %s\n' "$1" "$2" "$3"
}

sw_doctor_report() {
  if ! sw_ui_out; then
    return 0
  fi
  printf 'Tool\tState\tDetail\n%s' "${SW_DOCTOR_ROWS}" | sw_ui_table
  if [ "$1" -ne 0 ]; then
    sw_ui_log ERROR "a required tool is missing. install it and run shiwake doctor again."
    return 0
  fi
  sw_ui_done "Ready. Every tool shiwake needs is here."
}

sw_doctor_gum() {
  sw_dg_found="$(command -v gum 2>/dev/null || true)"
  if [ -z "${sw_dg_found}" ]; then
    sw_doctor_row gum missing "install with: brew install gum, or see https://github.com/charmbracelet/gum"
    return 1
  fi
  sw_dg_version="$(sw_flavor_version "$(gum --version 2>/dev/null || true)")"
  sw_doctor_row gum ok "${sw_dg_found}${sw_dg_version:+, ${sw_dg_version}}"
}

sw_flavor_version() {
  printf '%s\n' "$1" | awk '{
    for (i = 1; i <= NF; i++) {
      t = $i
      gsub(/[,;()]/, "", t)
      sub(/^v/, "", t)
      if (t ~ /^[0-9]+(\.[0-9]+)+[a-z0-9]*$/ || t ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) { print t; exit }
    }
  }'
}

sw_tool_line() {
  sw_tl_line="$(printf '%s\n' "$1" | awk '/BusyBox|This is not GNU/ { print; exit }')"
  if [ -z "${sw_tl_line}" ]; then
    sw_tl_line="$(printf '%s\n' "$1" | sed -n '1p')"
  fi
  printf '%s\n' "${sw_tl_line}"
}

sw_tool_flavor() {
  sw_tf_raw="$("$1" --version 2>&1 </dev/null)" || true
  sw_tf_text="$(sw_tool_line "${sw_tf_raw}")"
  sw_tf_version="$(sw_flavor_version "${sw_tf_text}")"
  sw_tf_os="${SHIWAKE_OS:-}"
  [ -n "${sw_tf_os}" ] || sw_tf_os="$(uname -s)"
  case "${sw_tf_text}" in
  *uutils*) sw_tf_name=uutils ;;
  *BusyBox*) sw_tf_name=busybox ;;
  *"This is not GNU"*)
    sw_tf_name=busybox
    sw_tf_version=""
    ;;
  *GNU* | *"(coreutils)"*) sw_tf_name=gnu ;;
  *)
    sw_tf_version=""
    case "$1:${sw_tf_os}" in
    *uutils*:* | */cargo/*:*) sw_tf_name=uutils ;;
    *:Darwin | *:*BSD) sw_tf_name=bsd ;;
    *) sw_tf_name=unknown ;;
    esac
    ;;
  esac
  printf '%s%s\n' "${sw_tf_name}" "${sw_tf_version:+ ${sw_tf_version}}"
}

sw_doctor_tool() {
  sw_dt_found="$(command -v "$1" 2>/dev/null || true)"
  if [ -z "${sw_dt_found}" ]; then
    sw_doctor_row "$1" missing "required, part of coreutils"
    return 1
  fi
  sw_dt_flavor="$(sw_tool_flavor "${sw_dt_found}")"
  sw_doctor_row "$1" ok "${sw_dt_found}, ${sw_dt_flavor}"
}

sw_doctor() {
  sw_dr_status=0
  sw_doctor_gum || sw_dr_status=1
  sw_doctor_tool mkdir || sw_dr_status=1
  sw_doctor_tool mv || sw_dr_status=1
  sw_doctor_report "${sw_dr_status}"
  return "${sw_dr_status}"
}
