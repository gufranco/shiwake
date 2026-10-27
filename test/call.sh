#!/bin/sh
[ -n "${ZSH_VERSION:-}" ] && emulate sh

SW_LIB="$(cd "$(dirname "$0")/../lib" && pwd)" || exit 1

# shellcheck source=SCRIPTDIR/../lib/core.sh
. "${SW_LIB}/core.sh"
# shellcheck source=SCRIPTDIR/../lib/cli.sh
. "${SW_LIB}/cli.sh"
# shellcheck source=SCRIPTDIR/../lib/doctor.sh
. "${SW_LIB}/doctor.sh"

"$@"
