# mpv-wrapper

[中文](README.zh.md)

`brew install mpv` installs only the command-line [mpv](https://mpv.io).
mpv-wrapper is a Homebrew cask that adds `/Applications/mpv.app`, which runs
that same binary, so mpv can open files from Finder, be the default player, and
start from the Dock, Launchpad or Spotlight. The app holds no copy of mpv, so
`brew upgrade mpv` upgrades it too. Tested on Apple Silicon only.

Homebrew used to ship mpv's app as the cask `stolendata-mpv`, which was disabled
on 2026-09-01 because it fails the Gatekeeper check. mpv's own
[macOS builds](https://github.com/mpv-player/mpv/releases) are ad-hoc signed and
update separately from Homebrew. mpv-wrapper builds the app on your Mac from the
formula you already have.

## Install

```sh
brew tap GuMengSama/tap
brew trust --cask GuMengSama/tap/mpv-wrapper   # required by Homebrew 7
brew install --cask mpv-wrapper
```

The cask installs the `mpv` formula if needed and compiles a small launcher,
which requires the Xcode Command Line Tools (`xcode-select --install`).

## Usage

Open videos from Finder by double-clicking, with Open With, or by dropping them
on the Dock icon. From a terminal:

```sh
open -a mpv video.mkv   # play a file in the app
open -a mpv             # open mpv's empty window
```

To make mpv the default player for a file type, select a file in Finder, choose
Get Info, set Open with to mpv, and click Change All.

## Uninstall

```sh
brew uninstall --cask mpv-wrapper        # keeps the mpv command
brew uninstall --zap --cask mpv-wrapper  # also removes prefs, saved state, log
```

`~/.config/mpv` is shared with the `mpv` command and is not removed.

## How it works

`app/mpv.app` is mpv's own bundle skeleton from `TOOLS/osxbundle` in the mpv
source: the Info.plist with mpv's file types, the icons, and an `mpv.conf` that
enables the pseudo-GUI. The cask adds two files when it installs:

```
/Applications/mpv.app/Contents/MacOS/
├── mpv           compiled src/launcher.c: sets MPVBUNDLE=true, execs ↓
└── mpv-formula → $(brew --prefix)/opt/mpv/bin/mpv
```

mpv behaves as an app only when `MPVBUNDLE=true`. macOS ignores the
Info.plist's `LSEnvironment` for a symlinked executable and will not launch a
shell script as an app, so a C launcher sets the variable and `exec`s the
symlink. macOS still sees a single `io.mpv` app, and the `opt/mpv` path does
not change when the formula is upgraded.

## Contributing

Report bugs and ask questions in
[issues](https://github.com/GuMengSama/mpv-wrapper/issues). To try a change,
fork this repository and
[homebrew-tap](https://github.com/GuMengSama/homebrew-tap), commit to `app/` or
`src/`, and build a release from your fork:

```sh
scripts/release.sh 1.0.1-yourname   # prints the steps to publish it
test/verify-app.sh                  # after installing the cask from your tap
```

Point the cask's `url` and `homepage` at your fork, and include the output of
`verify-app.sh` in your pull request. When updating `app/mpv.app` from upstream,
keep the category `video` and leave out `CFBundleShortVersionString`.
`brew audit --strict` reports "No binaries in App" because the launcher is
compiled at install time.

## License

GPL-2.0-or-later, like mpv. `app/mpv.app` is taken from mpv v0.41.0.
