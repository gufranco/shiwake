#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_args_positional() {
  if [ -z "$1" ]; then
    sw_cli_hint "the folder name is empty"
    return 1
  fi
  if [ -n "${SW_DIR}" ]; then
    sw_cli_hint "unexpected extra argument '$1'"
    return 1
  fi
  SW_DIR="$1"
}

sw_args_one() {
  case "$1" in
  --) SW_ARGS_DONE=yes ;;
  --dry-run) SW_DRY_RUN=yes ;;
  --json) SW_JSON=yes ;;
  --*=*)
    sw_cli_hint "unknown option '${1%%=*}'"
    return 1
    ;;
  -?*)
    sw_cli_hint "unknown option '$1'"
    return 1
    ;;
  *) sw_args_positional "$1" ;;
  esac
}

sw_args_parse() {
  SW_ARGS_DONE=no
  for sw_ap_arg in "$@"; do
    if [ "${SW_ARGS_DONE}" = yes ]; then
      sw_args_positional "${sw_ap_arg}" || return 1
      continue
    fi
    sw_args_one "${sw_ap_arg}" || return 1
  done
}
