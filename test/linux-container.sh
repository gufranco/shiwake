#!/bin/sh
set -eu

repo="$(cd "$(dirname "$0")/.." && pwd)"
image="${SHIWAKE_TEST_IMAGE:-ubuntu:26.04}"

docker run --rm \
  -v "${repo}:/repo" \
  -w /repo \
  -e SHIWAKE_TEST_SHELLS="${SHIWAKE_TEST_SHELLS:-}" \
  -e SHIWAKE_TEST_RECORD="${SHIWAKE_TEST_RECORD:-}" \
  "${image}" \
  sh -c '
    set -eu
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null
    apt-get install -y -qq --no-install-recommends \
      bats dash zsh mandoc file python3 ca-certificates >/dev/null
    exec "$@"
  ' sh "$@"
