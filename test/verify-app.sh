#!/bin/bash
# Behaviour check for an installed mpv.app wrapper.
# Opens a clip the way Finder does (Apple Event via LaunchServices) and checks
# what the user would see: one io.mpv app, bundle mode, the file playing, run
# by the current Homebrew mpv, and a clean quit.
#
# Usage: test/verify-app.sh [path/to/mpv.app]   (default: /Applications/mpv.app)
set -u

app="${1:-/Applications/mpv.app}"
# Resolved path: Finder-style Apple Events hand mpv the real path (/private/var/...).
work="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/mpv-wrapper-verify.XXXXXX")" && pwd -P)"
clip="$work/test clip.mp4"
log="$work/mpv.log"
failures=0

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; failures=$((failures + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# Polls until the command succeeds or ~10s pass.
wait_for() {
  for _ in $(seq 40); do
    eval "$1" && return 0
    sleep 0.25
  done
  return 1
}

app_pid() { pgrep -f "^$app/Contents/MacOS/" | head -1; }

finish() {
  osascript -e 'tell application id "io.mpv" to quit' >/dev/null 2>&1
  rm -rf "$work"
  echo
  if [ "$failures" -eq 0 ]; then echo "OK: all checks passed"; else echo "FAILED: $failures check(s)"; fi
  exit "$((failures > 0))"
}
trap finish EXIT

if [ ! -d "$app" ]; then
  fail "app exists at $app"
  exit
fi
pass "app exists at $app"

check "no quarantine attribute on the app" \
  '! xattr -r "$app" 2>/dev/null | grep -q com.apple.quarantine'

brew_prefix="$(brew --prefix)"
"$brew_prefix/bin/ffmpeg" -loglevel error -y -f lavfi -i testsrc=duration=30:size=320x180:rate=25 \
  -c:v libx264 -pix_fmt yuv420p "$clip" || { fail "generate test clip"; exit; }

open -a "$app" "$clip" --args --log-file="$log"

check "file opened from Finder-style Apple Event plays" \
  'wait_for "grep -q \"Opening done: $clip\" \"$log\" 2>/dev/null"'
check "bundle mode: reads the app's Resources/mpv.conf" \
  'grep -q "Reading config file $app/Contents/Resources/mpv.conf" "$log"'
check "LaunchServices sees one io.mpv app at this bundle path" \
  '[ "$(lsappinfo info -only bundlepath "$(app_pid)" | sed -n "s/.*=\"\(.*\)\"/\1/p")" = "$app" ]'

current_mpv="$(cd "$(brew --prefix mpv)" && pwd -P)"
check "runs the current Homebrew mpv ($current_mpv)" \
  'grep -q -- "-Dprefix=$current_mpv " "$log"'

osascript -e 'tell application id "io.mpv" to quit' >/dev/null 2>&1
check "quits cleanly" 'wait_for "[ -z \"\$(app_pid)\" ]"'
