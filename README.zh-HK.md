<div align="center">

<h1>shiwake</h1>

<strong>把資料夾裡的檔案按名稱首字母分到 A 至 Z 的子資料夾，絕不把一個檔案移到同名檔案上。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文 (香港)

[![ci](https://github.com/gufranco/shiwake/actions/workflows/ci.yml/badge.svg)](https://github.com/gufranco/shiwake/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/shiwake)](https://github.com/gufranco/shiwake/releases)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![shell](https://img.shields.io/badge/shell-POSIX%20sh-lightgrey)](#portability)

<p align="center">
  <a href="#quick-start"><strong>快速開始</strong></a> |
  <a href="#how-files-are-sorted">分類規則</a> |
  <a href="#development">開發</a>
</p>

</div>

一條指令，59 個測試，7 個 shell 模組。除了 POSIX 系統，不需要安裝任何東西。`shiwake` 是日文「仕分け」，意思是分揀：像郵局分揀信件一樣，把檔案分進各自的格子。姊妹工具 [kakikomi](https://github.com/gufranco/kakikomi)、[kiyome](https://github.com/gufranco/kiyome) 和 [yakitsuke](https://github.com/gufranco/yakitsuke) 負責寫入磁碟、清除磁碟和製作 VCD。

---

```console
$ shiwake ~/Downloads

Folder: /home/me/Downloads
Plan:   7 files into 5 folders named for their first letter

shiwake: warning: N/notes.txt already exists, so notes.txt stays where it is.
Sorted 6 of 7 files into 4 folders.
```

<a id="quick-start"></a>

## 快速開始

### 先決條件

| 工具 | 用途 | 安裝 |
|:-----|:----|:--------|
| `mkdir`、`mv` | 建立字母資料夾並移動檔案 | Linux 和 macOS 均已內置 |

### 安裝

```bash
brew install gufranco/tap/shiwake
```

或者從原始碼安裝：

```bash
git clone https://github.com/gufranco/shiwake.git
cd shiwake
make install
```

`make install` 會把工具本身、man 說明頁以及 bash、zsh 和 fish 的自動補全複製到 `~/.local` 下，並把 `shiwake` 放進 `~/.local/bin`；設定 `PREFIX` 可以改變位置。Homebrew formula 安裝的是同樣的檔案。

### 驗證

```console
$ shiwake doctor
mkdir              ok       /usr/bin/mkdir, uutils 0.10.0
mv                 ok       /usr/bin/mv, gnu 9.7
```

## 用法

| 指令 | 作用 |
|:--------|:--------|
| `shiwake [options] [folder]` | 整理指定的資料夾，未指定時整理目前的資料夾 |
| 不帶參數的 `shiwake` | 在終端機中執行時詢問要整理的資料夾，預設是目前的資料夾 |
| `shiwake doctor` | 列出 shiwake 需要的工具及其類型和版本 |
| `shiwake version`、`shiwake help` | 顯示版本或完整的用法說明 |

| 選項 | 效果 |
|:-------|:-------|
| `--dry-run` | 列出每一次移動，不作任何改動 |

```bash
shiwake ~/Downloads              # 整理下載資料夾
shiwake --dry-run .              # 查看整理目前的資料夾會怎樣移動
```

`--` 表示選項結束，所以 `shiwake -- -old` 會整理名為 `-old` 的資料夾。shiwake 遵循同系列工具共用的命令列約定，詳見 [FAMILY.md](FAMILY.md)。

<a id="how-files-are-sorted"></a>

## 分類規則

| 名稱的第一個字元 | 資料夾 |
|:----------------------------|:-------|
| `a` 至 `z` 或 `A` 至 `Z` | 該字母的大寫：`apple` 和 `Avocado` 都放進 `A` |
| 其他字元：數字、符號、帶重音的字母或非拉丁字母 | `#` |

- 只整理資料夾的頂層。子資料夾保持不變，包括之前執行時建立的字母資料夾，檔案會放進已有的字母資料夾。
- 符號連結像檔案一樣移動，從不跟隨，所以指向資料夾的連結也會作為連結移動。
- 名稱以點開頭的隱藏檔案，以及管道等特殊檔案，留在原處。
- 絕不把一個檔案移到另一個檔案上。如果 `N/notes.txt` 已經存在，`notes.txt` 會留在原處，shiwake 會說明這一點，執行仍然算成功。
- 如果字母資料夾應在的位置已經有檔案或連結，例如名為 `B` 的檔案，該字母的檔案都會留在原處，執行以狀態碼 1 結束。
- 在不區分大小寫的磁碟上（macOS 磁碟預設如此），名為 `a` 的檔案和資料夾 `A` 是同一個名稱，所以這個檔案會留在原處；在區分大小寫的磁碟上，它會移進 `A`。
- 所有名稱都原樣移動，包括含空格、換行、開頭短橫線或萬用字元的名稱。檔案用 shell 萬用字元尋找，`mv` 按最多 512 個檔案一批執行，而不是每個檔案執行一次。

<a id="portability"></a>

## 可攜性

全部是 POSIX `sh`，ShellCheck `-o all` 零警告。測試在 macOS 的 `/bin/sh`、系統內置的 bash 3.2 和 zsh、Homebrew 的最新 bash 和 zsh，以及 Ubuntu 的 `dash`、`bash` 和 `zsh` 下執行。

它能在五種常用工具集上執行：Linux 上的 GNU 或 uutils coreutils，以及 macOS 內置的工具、Homebrew 中較新的版本或 Homebrew 的 uutils 工具。macOS 內置而 Homebrew 有較新版本的工具，包括 bash 和 zsh，兩個版本都會測試。CI 在每種工具集上執行全部測試，`shiwake doctor` 會列出 `mkdir` 和 `mv` 的類型和版本，例如 `gnu 9.7`、`uutils 0.12.0` 或 `bsd`，讓錯誤報告說明用的是哪些工具。

<a id="development"></a>

## 開發

| 指令 | 說明 |
|:--------|:------------|
| `make lint` | 對所有腳本、測試和自動補全執行 ShellCheck，用 mandoc 檢查 man 說明頁 |
| `make test` | 在系統 `sh` 下執行 59 個 `bats` 測試 |
| `make test-all` | 在每種 shell 下執行同樣的測試，macOS 上包括 bash 和 zsh 的兩個版本 |
| `make coverage` | bashcov 行覆蓋率，以及 CI 強制的 100% 門檻 |

測試在真實檔案系統上整理真實的資料夾，只有故障透過 `PATH` 上的小包裝程式注入。每次推送到 `main` 都會執行 semantic-release：`feat` 或 `fix` 提交會發佈新版本，更新 [`lib/core.sh`](lib/core.sh) 裡的 `SHIWAKE_VERSION` 和 CHANGELOG，並更新 Homebrew formula。

## 授權

[MIT](LICENSE)。
