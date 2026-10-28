#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
duplicates=$(cat "${root}"/bin/shiwake "${root}"/lib/*.sh |
  sed -n 's/^\([a-z_][a-z0-9_]*\)() {$/\1/p' | sort | uniq -d)
if [ -n "${duplicates}" ]; then
  printf 'function defined more than once:\n%s\n' "${duplicates}" >&2
  exit 1
fi

unprefixed=$(cat "${root}"/bin/shiwake "${root}"/lib/*.sh |
  grep -oE '[$][{]?[A-Z][A-Z0-9_]*' | sed 's/^[$][{]*//' | sort -u |
  grep -vE '^(SW|SHIWAKE)_' | grep -vxE 'HOME|PATH|TMPDIR|ZSH_VERSION' || true)
if [ -n "${unprefixed}" ]; then
  printf 'environment variable without the SHIWAKE_ prefix:\n%s\n' "${unprefixed}" >&2
  exit 1
fi

scrub="for sw_inherited in \$(env | sed -n 's/^\\(SW_[A-Za-z0-9_]*\\)=.*/\\1/p'); do"
if ! grep -qF "${scrub}" "${root}/bin/shiwake"; then
  printf 'bin/shiwake must clear every inherited SW_ variable before it starts\n' >&2
  exit 1
fi
