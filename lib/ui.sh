#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${SW_LIB:?}/state.sh"

# shellcheck disable=SC2034
sw_ui_set() {
  SW_UI_ACCENT="$1"
  SW_UI_OK="$2"
  SW_UI_WARN="$3"
  SW_UI_ERR="$4"
  SW_UI_MUTED="$5"
  SW_UI_TEXT="$6"
  SW_UI_SURFACE="$7"
  SW_UI_HELP="$8"
}

sw_ui_palette() {
  case "$1" in
  kodougu) sw_ui_set "#F25D94" "#50FA7B" "#FFB86C" "#FF5555" "#6C7086" "#CDD6F4" "#313244" pink ;;
  catppuccin-mocha) sw_ui_set "#CBA6F7" "#A6E3A1" "#FAB387" "#F38BA8" "#6C7086" "#CDD6F4" "#313244" dark ;;
  catppuccin-latte) sw_ui_set "#8839EF" "#40A02B" "#FE640B" "#D20F39" "#8C8FA1" "#4C4F69" "#CCD0DA" light ;;
  dracula) sw_ui_set "#BD93F9" "#50FA7B" "#FFB86C" "#FF5555" "#6272A4" "#F8F8F2" "#44475A" dracula ;;
  nord) sw_ui_set "#88C0D0" "#A3BE8C" "#EBCB8B" "#BF616A" "#4C566A" "#D8DEE9" "#3B4252" dark ;;
  gruvbox) sw_ui_set "#FE8019" "#B8BB26" "#FABD2F" "#FB4934" "#928374" "#EBDBB2" "#3C3836" dark ;;
  tokyo-night) sw_ui_set "#7AA2F7" "#9ECE6A" "#E0AF68" "#F7768E" "#565F89" "#C0CAF5" "#292E42" tokyo-night ;;
  mono) sw_ui_set "" "" "" "" "" "" "" ascii ;;
  *) return 1 ;;
  esac
}

sw_ui_is_colour() {
  case "$1" in
  \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) return 0 ;;
  *) return 1 ;;
  esac
}

# shellcheck disable=SC2034
sw_ui_setup() {
  if ! sw_ui_palette "${SW_THEME}"; then
    sw_ui_palette mono
    SW_UI_PROBLEM="--theme must be one of ${SW_UI_THEMES}, got: ${SW_THEME}"
    return 1
  fi
  if [ -n "${SW_ACCENT}" ] && ! sw_ui_is_colour "${SW_ACCENT}"; then
    SW_UI_PROBLEM="KODOUGU_ACCENT must be a colour such as #CBA6F7, got: ${SW_ACCENT}"
    return 1
  fi
  if [ -n "${SW_ACCENT}" ]; then
    SW_UI_ACCENT="${SW_ACCENT}"
  fi
  if [ -n "${NO_COLOR:-}" ]; then
    sw_ui_palette mono
  fi
}

sw_ui_forced() {
  [ "${SHIWAKE_TEST_GUM:-}" = 1 ]
}

sw_ui_has_gum() {
  command -v gum >/dev/null 2>&1
}

sw_ui_prompts() {
  sw_ui_forced && return 0
  [ -t 0 ] && [ -t 2 ] && sw_ui_has_gum
}

sw_ui_err() {
  sw_ui_forced && return 0
  [ "${SW_UI_STEP}" = 1 ] && return 0
  [ -t 2 ] && sw_ui_has_gum
}

sw_ui_out() {
  sw_ui_forced && return 0
  [ -t 1 ] && sw_ui_has_gum
}

sw_gum() {
  if [ -n "${SW_UI_TEXT}" ]; then
    CLICOLOR_FORCE=1 gum "$@"
    return
  fi
  gum "$@"
}

sw_ui_ink() {
  sw_ui_colour="$1"
  shift
  if [ -z "${sw_ui_colour}" ]; then
    sw_gum style "$@"
    return
  fi
  sw_gum style --foreground "${sw_ui_colour}" "$@"
}

sw_ui_header() {
  sw_uh_name=$(sw_ui_ink "${SW_UI_ACCENT}" --bold -- "shiwake")
  sw_uh_number=$(sw_version | sed -n '1p')
  sw_uh_number="${sw_uh_number#shiwake }"
  sw_uh_version=$(sw_ui_ink "${SW_UI_MUTED}" -- "${sw_uh_number}")
  sw_uh_tagline=$(sw_ui_ink "${SW_UI_TEXT}" -- "${SW_TAGLINE}")
  sw_uh_top=$(sw_gum join --horizontal "${sw_uh_name}" "  " "${sw_uh_version}")
  sw_uh_body=$(sw_gum join --vertical "${sw_uh_top}" "${sw_uh_tagline}")
  printf '\n' >&2
  sw_gum style --border rounded --border-foreground "${SW_UI_ACCENT}" --padding "0 2" -- "${sw_uh_body}" >&2
  printf '\n' >&2
}

sw_ui_title() {
  printf '\n' >&2
  sw_ui_ink "${SW_UI_ACCENT}" --bold -- "$1" >&2
  printf '\n' >&2
}

sw_ui_titled() {
  if sw_ui_prompts; then
    sw_ui_title "$1"
  fi
}

sw_ui_lower_first() {
  printf '%s\n' "$1" | awk 'NR == 1 { a = substr($0, 1, 1); b = substr($0, 2, 1); if (a != tolower(a) && b != toupper(b)) { $0 = tolower(a) substr($0, 2) } } { print }'
}

sw_ui_log() {
  sw_ul_level="$1"
  sw_ul_text=$(sw_ui_lower_first "$2")
  case "${sw_ul_level}" in
  ERROR) sw_ul_colour="${SW_UI_ERR}" ;;
  WARN) sw_ul_colour="${SW_UI_WARN}" ;;
  *) sw_ul_colour="${SW_UI_OK}" ;;
  esac
  sw_ul_label=$(sw_ui_ink "${sw_ul_colour}" --bold -- "${sw_ul_level}")
  printf '%s shiwake: %s\n' "${sw_ul_label}" "${sw_ul_text}" >&2
}

sw_ui_choose() {
  sw_uc_header="$1"
  shift
  sw_gum choose --header "${sw_uc_header}" --cursor "> " --height 14 \
    --cursor.foreground "${SW_UI_ACCENT}" --selected.foreground "${SW_UI_ACCENT}" \
    --header.foreground "${SW_UI_TEXT}" "$@"
}

sw_ui_input() {
  sw_ui_header_text="$1"
  sw_ui_placeholder="$2"
  shift 2
  sw_gum input --header "${sw_ui_header_text}" --placeholder "${sw_ui_placeholder}" --prompt "> " \
    --prompt.foreground "${SW_UI_ACCENT}" --cursor.foreground "${SW_UI_ACCENT}" \
    --header.foreground "${SW_UI_TEXT}" --placeholder.foreground "${SW_UI_MUTED}" "$@"
}

sw_ui_write() {
  sw_gum write --header "$1" --placeholder "$2" --width 72 --height 8 --show-line-numbers \
    --cursor.foreground "${SW_UI_ACCENT}" --header.foreground "${SW_UI_TEXT}" \
    --placeholder.foreground "${SW_UI_MUTED}"
}

sw_ui_confirm() {
  sw_ucf_prompt="$1"
  sw_ucf_yes="$2"
  sw_ucf_no="$3"
  shift 3
  sw_gum confirm "${sw_ucf_prompt}" --affirmative "${sw_ucf_yes}" --negative "${sw_ucf_no}" \
    --prompt.foreground "${SW_UI_TEXT}" --selected.background "${SW_UI_ACCENT}" \
    --unselected.background "${SW_UI_SURFACE}" "$@"
}

sw_ui_summary() {
  sw_us2_pairs=$(($# / 2))
  while [ "${sw_us2_pairs}" -gt 0 ]; do
    sw_us2_label=$(printf '%-7s' "$1")
    sw_us2_label=$(sw_ui_ink "${SW_UI_MUTED}" -- "${sw_us2_label}")
    sw_us2_value=$(sw_ui_ink "${SW_UI_TEXT}" --bold -- "$2")
    shift 2
    set -- "$@" "${sw_us2_label} ${sw_us2_value}"
    sw_us2_pairs=$((sw_us2_pairs - 1))
  done
  printf '\n'
  sw_gum style --border rounded --border-foreground "${SW_UI_MUTED}" --padding "0 1" -- "$@"
  printf '\n'
}

sw_ui_spin() {
  sw_us_title="$1"
  sw_us_log="$2"
  shift 2
  (SW_UI_STEP=1 && "$@") 2>"${sw_us_log}" &
  sw_us_pid=$!
  if ! sw_ui_spin_wait "${sw_us_title}" "${sw_us_pid}"; then
    kill "${sw_us_pid}" 2>/dev/null
    exit 130
  fi
  sw_us_status=0
  wait "${sw_us_pid}" || sw_us_status=$?
  cat "${sw_us_log}" >&2
  return "${sw_us_status}"
}

sw_ui_spin_wait() {
  # shellcheck disable=SC2016
  sw_uw_loop='while kill -0 "$1" 2>/dev/null; do sleep 0.1; done'
  sw_gum spin --spinner dot --spinner.foreground "${SW_UI_ACCENT}" --title.foreground "${SW_UI_TEXT}" --title "$1" -- sh -c "${sw_uw_loop}" _ "$2" >&2
}

sw_ui_table() {
  sw_ut_line="-"
  if [ -n "${SW_UI_TEXT}" ]; then
    sw_ut_line=$(printf '\342\224\200')
  fi
  sw_ut_body=$(sw_ui_table_body "${sw_ut_line}")
  sw_gum style --border rounded --border-foreground "${SW_UI_MUTED}" --padding "0 1" -- "${sw_ut_body}"
}

sw_ui_table_body() {
  LC_ALL=C awk -F '\t' -v acc="${SW_UI_ACCENT}" -v ok="${SW_UI_OK}" -v warn="${SW_UI_WARN}" \
    -v bad="${SW_UI_ERR}" -v txt="${SW_UI_TEXT}" -v mut="${SW_UI_MUTED}" -v dash="$1" \
    -f "${SW_LIB}/table.awk"
}

sw_ui_done() {
  printf '\n'
  sw_ui_ink "${SW_UI_OK}" --bold -- "$1"
}

sw_ui_badge() {
  sw_ub_colour="$1"
  shift
  if [ -z "${sw_ub_colour}" ]; then
    sw_gum style --bold --underline --padding "0 1" -- "$*"
    return
  fi
  sw_gum style --background "${sw_ub_colour}" --foreground "#1E1E2E" --bold --padding "0 1" -- "$*"
}

sw_ui_chip() {
  if [ -z "${SW_UI_SURFACE}" ]; then
    sw_gum style --padding "0 1" -- "$1"
    return
  fi
  sw_gum style --background "${SW_UI_SURFACE}" --foreground "${SW_UI_TEXT}" --padding "0 1" -- "$1"
}

sw_ui_danger() {
  sw_ud_title=$(sw_ui_ink "${SW_UI_ERR}" --bold -- "$1")
  shift
  sw_gum style --border thick --border-foreground "${SW_UI_ERR}" --padding "0 1" -- "${sw_ud_title}" "$@" >&2
}

sw_ui_markdown() {
  awk '
    NR == 1 {
      split($0, head, " - ")
      printf "# %s\n\n%s\n", head[1], head[2]
      next
    }
    /^[a-z][a-z ]*:$/ {
      if (open) { print "```" }
      printf "\n## %s\n\n```text\n", toupper(substr($0, 1, 1)) substr($0, 2, length($0) - 2)
      open = 1
      next
    }
    { print }
    END { if (open) { print "```" } }
  '
}
