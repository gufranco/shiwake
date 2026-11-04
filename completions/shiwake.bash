# shellcheck shell=bash
# shellcheck disable=SC2207

_shiwake() {
  local cur words
  cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ "${COMP_WORDS[COMP_CWORD - 1]}" == "--theme" ]]; then
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
  fi
  if [[ "${cur}" == -* ]]; then
    COMPREPLY=($(compgen -W "--dry-run --json --theme" -- "${cur}"))
    return
  fi
  words="$(compgen -d -- "${cur}" || true)"
  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    words="doctor version help ${words}"
  fi
  COMPREPLY=($(compgen -W "${words}" -- "${cur}"))
}

complete -o filenames -F _shiwake shiwake
