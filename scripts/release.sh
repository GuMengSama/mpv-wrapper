#!/bin/bash
# Builds the release download for the mpv-wrapper cask (GuMengSama/homebrew-tap) from the committed tree.
# Archives the last commit that changed the shipped files: git archive embeds
# the commit id, so the sha256 changes only when app/, src/ or LICENSE do.
#
# Usage: scripts/release.sh 1.0.0
set -euo pipefail

version="${1:?usage: scripts/release.sh <version>}"
cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain -- app src LICENSE)" ]; then
  echo "app/, src/ or LICENSE has uncommitted changes; commit them first." >&2
  exit 1
fi

mkdir -p dist
out="dist/mpv-wrapper-$version.tar.gz"
git archive --format=tar.gz -o "$out" "$(git log -1 --format=%H -- app src LICENSE)" app src LICENSE

echo "$out"
echo "sha256 $(shasum -a 256 "$out" | cut -d' ' -f1)"
echo
echo "Next: tag v$version, and upload $out"
echo "to the GitHub release v$version (gh release create v$version $out), then set"
echo "version/sha256 in homebrew-tap/Casks/mpv-wrapper.rb."
