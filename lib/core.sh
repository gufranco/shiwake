#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

SHIWAKE_VERSION="1.1.1"

sw_version() {
  printf '%s %s\n' "${SW_PROG}" "${SHIWAKE_VERSION}"
}

sw_wrap() {
  awk -v width="${SW_WIDTH}" -v indent="$1" '
    function pad(n,   s) {
      s = ""
      while (n-- > 0) { s = s " " }
      return s
    }
    length($0) <= width { print; next }
    {
      match($0, /^ */)
      n = split($0, word, " ")
      out = substr($0, 1, RLENGTH) word[1]
      for (i = 2; i <= n; i++) {
        if (length(out) + 1 + length(word[i]) > width) {
          print out
          out = pad(indent) word[i]
        } else {
          out = out " " word[i]
        }
      }
      print out
    }'
}

sw_terminal() {
  [ "${SHIWAKE_TERMINAL:-}" = 1 ] || [ -t 1 ]
}

sw_say() {
  sw_sy_text="$2"
  if [ "${#sw_sy_text}" -le "${SW_WIDTH}" ] || ! sw_terminal; then
    printf '%s\n' "${sw_sy_text}"
    return 0
  fi
  printf '%s\n' "${sw_sy_text}" | sw_wrap "$1"
}

sw_warning() {
  sw_say 0 "${SW_PROG}: warning: $*" >&2
}

sw_error() {
  sw_say 0 "${SW_PROG}: $*" >&2
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
