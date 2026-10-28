#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_doctor_row() {
  printf '%-18s %-8s %s\n' "$1" "$2" "$3"
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

sw_tool_flavor() {
  sw_tf_raw="$("$1" --version 2>&1 </dev/null)" || true
  sw_tf_text="$(printf '%s\n' "${sw_tf_raw}" | sed -n '1p')"
  sw_tf_version="$(sw_flavor_version "${sw_tf_text}")"
  sw_tf_os="${SHIWAKE_OS:-}"
  [ -n "${sw_tf_os}" ] || sw_tf_os="$(uname -s)"
  case "${sw_tf_text}" in
  *uutils*) sw_tf_name=uutils ;;
  *BusyBox*) sw_tf_name=busybox ;;
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
  sw_doctor_tool mkdir || sw_dr_status=1
  sw_doctor_tool mv || sw_dr_status=1
  return "${sw_dr_status}"
}
