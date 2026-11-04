#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

SHIWAKE_VERSION="1.3.0"

sw_version() {
  printf '%s %s\n' "${SW_PROG}" "${SHIWAKE_VERSION}"
}

sw_say() {
  printf '%s\n' "$1"
}

sw_warning() {
  if sw_ui_err; then
    sw_ui_log WARN "$*"
    return 0
  fi
  sw_say "${SW_PROG}: warning: $*" >&2
}

sw_error() {
  if sw_ui_err; then
    sw_ui_log ERROR "$*"
    return 0
  fi
  sw_say "${SW_PROG}: $*" >&2
}

sw_json_string() {
  printf '%s' "$1" | awk '
    BEGIN { for (i = 1; i < 32; i++) code[sprintf("%c", i)] = sprintf("\\u%04x", i) }
    function escape(s,   r, c, i) {
      r = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") r = r "\\\\"
        else if (c == "\"") r = r "\\\""
        else if (c in code) r = r code[c]
        else r = r c
      }
      return r
    }
    { out = out (NR > 1 ? "\\n" : "") escape($0) }
    END { printf "\"%s\"", out }'
}

sw_plural() {
  if [ "$1" -eq 1 ]; then
    printf '1 %s\n' "$2"
  else
    printf '%s %ss\n' "$1" "$2"
  fi
}
