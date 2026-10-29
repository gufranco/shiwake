<div align="center">

<h1>shiwake</h1>

<strong>把文件夹里的文件按名称首字母分到 A 到 Z 的子文件夹，绝不把一个文件移到同名文件上。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/shiwake/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/shiwake/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/shiwake?style=flat-square&label=release)](https://github.com/gufranco/shiwake/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/shiwake?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速开始</strong></a> |
  <a href="#how-files-are-sorted">分类规则</a> |
  <a href="#development">开发</a>
</p>

</div>

一条命令，67 个测试，7 个 shell 模块。除了 POSIX 系统，不需要安装任何东西。`shiwake` 是日语「仕分け」，意为分拣：像邮局分拣信件一样，把文件分进各自的格子。姊妹工具 [kakikomi](https://github.com/gufranco/kakikomi)、[kiyome](https://github.com/gufranco/kiyome) 和 [yakitsuke](https://github.com/gufranco/yakitsuke) 负责写入磁盘、擦除磁盘和制作 VCD。

---

```console
$ shiwake ~/Downloads

Folder: /home/me/Downloads
Plan:   7 files into 5 folders named for their first letter

shiwake: warning: N/notes.txt already exists, so notes.txt stays where it is.
Sorted 6 of 7 files into 4 folders.
```

<a id="quick-start"></a>

## 快速开始

### 前置条件

| 工具 | 用途 | 安装 |
|:-----|:----|:--------|
| `mkdir`、`mv` | 创建字母文件夹并移动文件 | Linux 和 macOS 都自带 |

### 安装

```bash
brew install gufranco/tap/shiwake
```

或者从源码安装：

```bash
git clone https://github.com/gufranco/shiwake.git
cd shiwake
make install
```

`make install` 会把工具本身、man 手册以及 bash、zsh 和 fish 的补全复制到 `~/.local` 下，并把 `shiwake` 放进 `~/.local/bin`；设置 `PREFIX` 可以改变位置。Homebrew formula 安装的是同样的文件。

### 验证

```console
$ shiwake doctor
mkdir              ok       /usr/bin/mkdir, uutils 0.10.0
mv                 ok       /usr/bin/mv, gnu 9.7
```

## 用法

| 命令 | 作用 |
|:--------|:--------|
| `shiwake [options] [folder]` | 整理指定的文件夹，不指定时整理当前文件夹 |
| 不带参数的 `shiwake` | 在终端中运行时询问要整理的文件夹，默认是当前文件夹 |
| `shiwake doctor` | 列出 shiwake 需要的工具及其类型和版本 |
| `shiwake version`、`shiwake help` | 显示版本或完整的用法说明 |

| 选项 | 效果 |
|:-------|:-------|
| `--dry-run` | 列出每一次移动，不做任何改动 |
| `--json` | 以一个 JSON 对象输出结果，供脚本使用 |

```bash
shiwake ~/Downloads              # 整理下载文件夹
shiwake --dry-run .              # 查看整理当前文件夹会怎样移动
```

`--` 表示选项结束，所以 `shiwake -- -old` 会整理名为 `-old` 的文件夹。shiwake 遵循同系列工具共用的命令行约定，详见 [FAMILY.md](FAMILY.md)。

<a id="how-files-are-sorted"></a>

## 分类规则

| 名称的第一个字符 | 文件夹 |
|:----------------------------|:-------|
| `a` 到 `z` 或 `A` 到 `Z` | 该字母的大写：`apple` 和 `Avocado` 都进 `A` |
| 其他字符：数字、符号、带重音的字母或非拉丁字母 | `#` |

- 只整理文件夹的顶层。子文件夹保持不变，包括之前运行时建立的字母文件夹，文件会放进已有的字母文件夹。
- 符号链接像文件一样移动，从不跟随，所以指向文件夹的链接也会作为链接移动。
- 名称以点开头的隐藏文件，以及管道等特殊文件，留在原处。
- 绝不把一个文件移到另一个文件上。如果 `N/notes.txt` 已经存在，`notes.txt` 会留在原处，shiwake 会说明这一点，运行仍然算成功。
- 如果字母文件夹应在的位置已经有文件或链接，例如名为 `B` 的文件，该字母的文件都会留在原处，运行以状态码 1 结束。
- 在不区分大小写的磁盘上（macOS 磁盘默认如此），名为 `a` 的文件和文件夹 `A` 是同一个名字，所以这个文件会留在原处；在区分大小写的磁盘上，它会移进 `A`。
- 所有名称都原样移动，包括含空格、换行、开头短横线或通配符的名称。文件用 shell 通配符查找，`mv` 按最多 512 个文件一批执行，而不是每个文件执行一次。

<a id="portability"></a>

## 可移植性

全部是 POSIX `sh`，ShellCheck `-o all` 零告警。测试在 macOS 的 `/bin/sh`、系统自带的 bash 3.2 和 zsh、Homebrew 的最新 bash 和 zsh，以及 Ubuntu 的 `dash`、`bash` 和 `zsh` 下运行。

它能在五种常用工具集上运行：Linux 上的 GNU 或 uutils coreutils，以及 macOS 自带的工具、Homebrew 中更新的版本或 Homebrew 的 uutils 工具。macOS 自带而 Homebrew 有更新版本的工具，包括 bash 和 zsh，两个版本都会测试。CI 在每种工具集上运行全部测试，`shiwake doctor` 会列出 `mkdir` 和 `mv` 的类型和版本，例如 `gnu 9.7`、`uutils 0.12.0` 或 `bsd`，让错误报告说明用的是哪些工具。

<a id="development"></a>

## 开发

| 命令 | 说明 |
|:--------|:------------|
| `make fmt` | 用 shfmt 格式化所有脚本 |
| `make lint` | 运行 shfmt，对所有脚本、测试和补全运行 ShellCheck，用 mandoc 检查 man 手册 |
| `make test` | 在系统 `sh` 下运行 `bats` 测试 |
| `make test-all` | 在每种 shell 下运行同样的测试，macOS 上包括 bash 和 zsh 的两个版本 |
| `make test-linux` | 在 Ubuntu 容器中运行同样的测试 |
| `make coverage` | 合并这台 Mac 与 Ubuntu 容器中的 bashcov 行覆盖率，以及 CI 强制的 100% 门槛 |

测试在真实文件系统上整理真实的文件夹，只有故障通过 `PATH` 上的小包装程序注入。推送到 `main` 且 CI 通过后会运行 semantic-release：`feat` 或 `fix` 提交会发布新版本，更新 [`lib/core.sh`](lib/core.sh) 里的 `SHIWAKE_VERSION` 和 CHANGELOG，并更新 Homebrew formula。

## 许可证

[MIT](LICENSE)。
