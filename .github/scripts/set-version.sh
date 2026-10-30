#!/bin/sh
set -eu

version=${1:?version required}
root=$(cd "$(dirname "$0")/../.." && pwd)
core="${root}/lib/core.sh"

if ! grep -q '^SHIWAKE_VERSION=' "${core}"; then
  printf 'no SHIWAKE_VERSION assignment found in %s\n' "${core}" >&2
  exit 1
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/shiwake-version-XXXXXX")
sed "s/^SHIWAKE_VERSION=\".*\"$/SHIWAKE_VERSION=\"${version}\"/" "${core}" >"${tmp}"
cat "${tmp}" >"${core}"
rm -f "${tmp}"

reported=$("${root}/bin/shiwake" --version)
printf 'version set to %s\n' "${reported}"
