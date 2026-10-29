# shellcheck shell=bash
# shellcheck disable=SC2207

_shiwake() {
  local cur words
  cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ "${cur}" == -* ]]; then
    COMPREPLY=($(compgen -W "--dry-run --json" -- "${cur}"))
    return
  fi
  words="$(compgen -d -- "${cur}" || true)"
  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    words="doctor version help ${words}"
  fi
  COMPREPLY=($(compgen -W "${words}" -- "${cur}"))
}

complete -o filenames -F _shiwake shiwake
