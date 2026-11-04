#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/bin"
mkdir -p "${demo}/Downloads/N"
for name in apple-pie.pdf banana-bread.txt Bowie-live.mp3 cherry-blossom.jpg 1999-tour.mp4 notes.txt nightfall.mkv avocado.png; do
  printf 'x\n' >"${demo}/Downloads/${name}"
done
printf 'old\n' >"${demo}/Downloads/N/notes.txt"
