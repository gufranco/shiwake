#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

SHIWAKE_VERSION="1.0.0"

sw_version() {
  printf '%s %s\n' "${SW_PROG}" "${SHIWAKE_VERSION}"
}

sw_warning() {
  printf '%s: warning: %s\n' "${SW_PROG}" "$*" >&2
}

sw_error() {
  printf '%s: %s\n' "${SW_PROG}" "$*" >&2
}

sw_plural() {
  if [ "$1" -eq 1 ]; then
    printf '1 %s\n' "$2"
  else
    printf '%s %ss\n' "$1" "$2"
  fi
}
