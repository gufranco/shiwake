#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

sw_open_folder() {
  case "${SW_DIR}" in
  \~) SW_DIR="${HOME}" ;;
  \~/*) SW_DIR="${HOME}/${SW_DIR#\~/}" ;;
  *) ;;
  esac
  if [ ! -e "${SW_DIR}" ]; then
    sw_error "no such folder: ${SW_DIR}"
    return 1
  fi
  if [ ! -d "${SW_DIR}" ]; then
    sw_error "not a folder: ${SW_DIR}"
    return 1
  fi
  if ! cd -- "${SW_DIR}" 2>/dev/null; then
    sw_error "cannot open the folder: ${SW_DIR}"
    return 1
  fi
  SW_DIR="$(pwd -P)"
}

sw_movable() {
  # shellcheck disable=SC2254
  case "$1" in
  $2*) ;;
  *) return 1 ;;
  esac
  [ -L "$1" ] && return 0
  [ -f "$1" ]
}

sw_fits() {
  [ -e "$1/$2" ] || [ -L "$1/$2" ] || return 0
  sw_warning "$1/$2 already exists, so $2 stays where it is."
  SW_KEPT=$((SW_KEPT + 1))
  return 1
}

sw_blocked() {
  [ -L "$1" ] || { [ -e "$1" ] && [ ! -d "$1" ]; } || return 1
  if [ "${SW_LAST_BLOCKED}" != "$1" ]; then
    sw_error "$1 is not a folder, so the files that belong in it stay where they are."
    SW_LAST_BLOCKED="$1"
  fi
  return 0
}

sw_filled() {
  [ "$2" -gt 0 ] || return 0
  [ "${SW_LAST_FILLED}" != "$1" ] || return 0
  SW_FILLED=$((SW_FILLED + 1))
  SW_LAST_FILLED="$1"
}

sw_tally() {
  SW_FOUND=$((SW_FOUND + $# - 1))
  [ "${SW_LAST_FOUND}" != "$1" ] || return 0
  SW_FOLDERS=$((SW_FOLDERS + 1))
  SW_LAST_FOUND="$1"
}

sw_show() {
  sw_sh_bucket="$1"
  shift
  for sw_sh_file in "$@"; do
    sw_say 0 "${sw_sh_file} -> ${sw_sh_bucket}/"
  done
  SW_MOVED=$((SW_MOVED + $#))
  sw_filled "${sw_sh_bucket}" "$#"
}

sw_landed() {
  [ -e "$1/$2" ] || [ -L "$1/$2" ] || return 1
  [ ! -e "$2" ] && [ ! -L "$2" ]
}

sw_reconcile() {
  sw_rc_bucket="$1"
  shift
  sw_rc_moved=0
  for sw_rc_file in "$@"; do
    if sw_landed "${sw_rc_bucket}" "${sw_rc_file}"; then
      sw_rc_moved=$((sw_rc_moved + 1))
    fi
  done
  SW_MOVED=$((SW_MOVED + sw_rc_moved))
  SW_FAILED=$((SW_FAILED + $# - sw_rc_moved))
  sw_filled "${sw_rc_bucket}" "${sw_rc_moved}"
}

sw_said() {
  printf '%s\n' "$2" | while IFS= read -r sw_sd_line; do
    [ -z "${sw_sd_line}" ] || sw_error "$1 said: ${sw_sd_line}"
  done
}

sw_move() {
  sw_mo_bucket="$1"
  shift
  if [ ! -d "${sw_mo_bucket}" ] && ! sw_mo_said="$(mkdir -- "${sw_mo_bucket}" 2>&1)"; then
    sw_error "could not create the folder ${sw_mo_bucket}."
    sw_said mkdir "${sw_mo_said}"
    SW_FAILED=$((SW_FAILED + $#))
    return 0
  fi
  if sw_mo_said="$(mv -- "$@" "${sw_mo_bucket}/" 2>&1)"; then
    SW_MOVED=$((SW_MOVED + $#))
    sw_filled "${sw_mo_bucket}" "$#"
    return 0
  fi
  sw_reconcile "${sw_mo_bucket}" "$@"
  sw_said mv "${sw_mo_said}"
}

sw_flush() {
  sw_fl_mode="$1"
  shift
  if [ "${sw_fl_mode}" = tally ]; then
    sw_tally "$@"
    return 0
  fi
  if sw_blocked "$1"; then
    SW_FAILED=$((SW_FAILED + $# - 1))
    return 0
  fi
  "sw_${sw_fl_mode}" "$@"
}

sw_visit() {
  sw_vi_mode="$1"
  sw_vi_bucket="$2"
  sw_vi_pattern="$3"
  set --
  # shellcheck disable=SC2231
  for sw_vi_file in ${sw_vi_pattern}*; do
    sw_movable "${sw_vi_file}" "${sw_vi_pattern}" || continue
    [ "${sw_vi_mode}" = tally ] || sw_fits "${sw_vi_bucket}" "${sw_vi_file}" || continue
    set -- "$@" "${sw_vi_file}"
    [ "$#" -lt "${SW_BATCH}" ] && continue
    sw_flush "${sw_vi_mode}" "${sw_vi_bucket}" "$@"
    set --
  done
  [ "$#" -eq 0 ] || sw_flush "${sw_vi_mode}" "${sw_vi_bucket}" "$@"
}

sw_scan() {
  set -f
  # shellcheck disable=SC2086
  set -- "$1" ${SW_BUCKETS}
  set +f
  sw_sc_mode="$1"
  shift
  for sw_sc_entry in "$@"; do
    sw_visit "${sw_sc_mode}" "${sw_sc_entry%%:*}" "${sw_sc_entry#*:}"
  done
}
