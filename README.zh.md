# mpv-wrapper

[English](README.md)

`brew install mpv` 只安装命令行版的 [mpv](https://mpv.io)。mpv-wrapper 是一个
Homebrew cask，会添加 `/Applications/mpv.app`，运行的就是同一个 mpv 程序。这样
mpv 就能从访达打开文件、作为默认播放器，也能从程序坞、启动台或聚焦搜索启动。应用里
没有另一份 mpv，所以 `brew upgrade mpv` 会同时升级它。目前只在 Apple 芯片上测试过。

Homebrew 过去通过 cask `stolendata-mpv` 提供 mpv 的应用，它因无法通过 Gatekeeper
检查已于 2026-09-01 被停用。mpv 官方的
[macOS 版本](https://github.com/mpv-player/mpv/releases) 只有临时签名（ad-hoc），
并且与 Homebrew 分开更新。mpv-wrapper 则在你的 Mac 上用你已安装的 formula 构建应用。

## 安装

```sh
brew tap GuMengSama/tap
brew trust --cask GuMengSama/tap/mpv-wrapper   # Homebrew 7 要求
brew install --cask mpv-wrapper
```

如有需要，cask 会安装 `mpv` formula，并编译一个小启动器，这需要 Xcode Command Line
Tools（`xcode-select --install`）。

## 使用

在访达中双击视频、使用“打开方式”，或把视频拖到程序坞图标上即可播放。在终端中：

```sh
open -a mpv video.mkv   # 在应用中播放文件
open -a mpv             # 打开 mpv 的空白窗口
```

要把 mpv 设为某类文件的默认播放器，在访达中选中文件，选择“显示简介”，把“打开方式”
设为 mpv，然后点击“全部更改”。

## 卸载

```sh
brew uninstall --cask mpv-wrapper        # 保留 mpv 命令
brew uninstall --zap --cask mpv-wrapper  # 同时删除偏好设置、窗口状态和日志
```

`~/.config/mpv` 与 `mpv` 命令共用，不会被删除。

## 工作原理

`app/mpv.app` 是 mpv 源码中 `TOOLS/osxbundle` 自带的应用包骨架：包含 mpv 文件类型
的 Info.plist、图标，以及启用伪图形界面（pseudo-GUI）的 `mpv.conf`。cask 安装时会
加入两个文件：

```
/Applications/mpv.app/Contents/MacOS/
├── mpv           编译后的 src/launcher.c：设置 MPVBUNDLE=true，然后 exec ↓
└── mpv-formula → $(brew --prefix)/opt/mpv/bin/mpv
```

只有在 `MPVBUNDLE=true` 时，mpv 才会以应用方式运行。可执行文件是符号链接时，macOS
会忽略 Info.plist 里的 `LSEnvironment`，也不会把 shell 脚本作为应用启动，所以由一个
C 启动器设置该变量并 `exec` 符号链接。macOS 看到的仍然只有一个 `io.mpv` 应用，而
`opt/mpv` 路径在 formula 升级后保持不变。

## 参与贡献

问题和建议请提交到 [issues](https://github.com/GuMengSama/mpv-wrapper/issues)。
要试验修改，先 fork 本仓库和 [homebrew-tap](https://github.com/GuMengSama/homebrew-tap)，
把修改提交到 `app/` 或 `src/`，再从你的 fork 构建发布包：

```sh
scripts/release.sh 1.0.1-yourname   # 输出发布步骤
test/verify-app.sh                  # 从你的 tap 安装 cask 之后运行
```

把 cask 的 `url` 和 `homepage` 改成你的 fork，并在 pull request 中附上
`verify-app.sh` 的输出。从上游更新 `app/mpv.app` 时，保留分类 `video`，且不要加回
`CFBundleShortVersionString`。由于启动器在安装时编译，`brew audit --strict` 会报告
"No binaries in App"。

## 许可证

GPL-2.0-or-later，与 mpv 相同。`app/mpv.app` 取自 mpv v0.41.0。
