<div align="center">

<h1>shiwake</h1>

<strong>フォルダ内のファイルを、名前の最初の文字ごとに A から Z のサブフォルダへ仕分けます。同名のファイルを上書きすることはありません。</strong>

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://github.com/gufranco/shiwake/actions/workflows/ci.yml/badge.svg)](https://github.com/gufranco/shiwake/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/shiwake)](https://github.com/gufranco/shiwake/releases)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![shell](https://img.shields.io/badge/shell-POSIX%20sh-lightgrey)](#portability)

<p align="center">
  <a href="#quick-start"><strong>クイックスタート</strong></a> |
  <a href="#how-files-are-sorted">仕分けのルール</a> |
  <a href="#development">開発</a>
</p>

</div>

コマンドは一つ、テストは 59 件、シェルモジュールは 7 個。POSIX システム以外に必要なものはありません。`shiwake` は「仕分け」です。郵便局が手紙を振り分けるように、ファイルをそれぞれの箱に振り分けます。姉妹ツールの [kakikomi](https://github.com/gufranco/kakikomi)、[kiyome](https://github.com/gufranco/kiyome)、[yakitsuke](https://github.com/gufranco/yakitsuke) は、ディスクの書き込み、ディスクの消去、ビデオ CD の作成を行います。

---

```console
$ shiwake ~/Downloads

Folder: /home/me/Downloads
Plan:   7 files into 5 folders named for their first letter

shiwake: warning: N/notes.txt already exists, so notes.txt stays where it is.
Sorted 6 of 7 files into 4 folders.
```

<a id="quick-start"></a>

## クイックスタート

### 必要なもの

| ツール | 用途 | インストール |
|:-----|:----|:--------|
| `mkdir`、`mv` | 文字ごとのフォルダを作り、ファイルを移動 | Linux と macOS に標準で入っています |

### インストール

```bash
brew install gufranco/tap/shiwake
```

ソースからインストールする場合:

```bash
git clone https://github.com/gufranco/shiwake.git
cd shiwake
make install
```

`make install` はツール本体、man ページ、bash・zsh・fish の補完を `~/.local` 以下にコピーし、`shiwake` を `~/.local/bin` に置きます。場所を変えるには `PREFIX` を指定します。Homebrew の formula も同じファイルをインストールします。

### 確認

```console
$ shiwake doctor
mkdir              ok       /usr/bin/mkdir, uutils 0.10.0
mv                 ok       /usr/bin/mv, gnu 9.7
```

## 使い方

| コマンド | 目的 |
|:--------|:--------|
| `shiwake [options] [folder]` | 指定したフォルダを仕分けます。省略すると現在のフォルダ |
| 引数なしの `shiwake` | 端末で実行すると、現在のフォルダを既定値としてフォルダを尋ねます |
| `shiwake doctor` | 必要なツールと、それぞれの系統とバージョンを表示 |
| `shiwake version`、`shiwake help` | バージョン、または使い方の全文を表示 |

| オプション | 効果 |
|:-------|:-------|
| `--dry-run` | 移動をすべて一覧表示し、何も変更しません |

```bash
shiwake ~/Downloads              # ダウンロードフォルダを仕分ける
shiwake --dry-run .              # 現在のフォルダを仕分けた場合の結果を確認する
```

`--` でオプションが終わるので、`shiwake -- -old` は `-old` という名前のフォルダを仕分けます。shiwake は姉妹ツールと共通のコマンドライン規約に従います。規約は [FAMILY.md](FAMILY.md) にあります。

<a id="how-files-are-sorted"></a>

## 仕分けのルール

| 名前の最初の文字 | フォルダ |
|:----------------------------|:-------|
| `a` から `z`、または `A` から `Z` | その文字の大文字。`apple` も `Avocado` も `A` へ |
| それ以外。数字、記号、アクセント付きの文字やラテン文字以外の文字 | `#` |

- 仕分けるのはフォルダの直下だけです。サブフォルダは、以前の実行で作られた文字フォルダも含めてそのまま残り、既存の文字フォルダにはファイルが追加されます。
- シンボリックリンクはファイルと同じように移動し、リンク先はたどりません。フォルダへのリンクもリンクのまま移動します。
- 名前がドットで始まる隠しファイルと、パイプなどの特殊ファイルは移動しません。
- ファイルを別のファイルの上に移動することはありません。`N/notes.txt` がすでにあれば、`notes.txt` は元の場所に残り、shiwake がその旨を表示します。実行は成功として終わります。
- 文字フォルダが入るべき場所に、`B` という名前のファイルなど、ファイルやリンクがすでにある場合、その文字のファイルは移動せず、終了ステータスは 1 になります。
- 大文字と小文字を区別しないディスク（macOS の既定）では、`a` というファイルと `A` フォルダは同じ名前になるため、そのファイルは移動しません。区別するディスクでは `A` に移動します。
- 空白、改行、先頭のダッシュ、グロブ文字を含む名前も、そのまま移動します。ファイルはシェルのグロブで探し、`mv` はファイルごとではなく最大 512 件の束ごとに一度だけ実行します。

<a id="portability"></a>

## 移植性

すべて POSIX `sh` で、ShellCheck `-o all` の指摘はゼロです。テストは macOS の `/bin/sh`、システムの bash 3.2 と zsh、Homebrew の最新の bash と zsh、そして Ubuntu の `dash`、`bash`、`zsh` で実行します。

Linux の GNU coreutils と uutils coreutils、macOS 標準のツール、その新しい Homebrew 版、Homebrew の uutils ツールという、よく使われる 5 つのツールセットのどれでも動きます。macOS 標準のツールのうち Homebrew に新しい版があるものは、bash と zsh も含めて、両方の版でテストします。CI はそれぞれで全テストを実行し、`shiwake doctor` は `mkdir` と `mv` の系統とバージョン（`gnu 9.7`、`uutils 0.12.0`、`bsd` など）を表示するので、不具合報告でどのツールが動いたかが分かります。

<a id="development"></a>

## 開発

| コマンド | 説明 |
|:--------|:------------|
| `make lint` | すべてのスクリプト、テスト、補完に ShellCheck、man ページに mandoc |
| `make test` | システムの `sh` で 59 件の `bats` テスト |
| `make test-all` | すべてのシェルで同じテスト。macOS では bash と zsh の両方の版を含みます |
| `make coverage` | bashcov の行カバレッジと、CI が強制する 100% のゲート |

テストは実際のファイルシステム上の実際のフォルダを仕分けます。故障だけを `PATH` 上の小さなラッパーで注入します。`main` への push ごとに semantic-release が動き、`feat` か `fix` のコミットでリリースを公開し、[`lib/core.sh`](lib/core.sh) の `SHIWAKE_VERSION` と CHANGELOG を更新し、Homebrew の formula を更新します。

## ライセンス

[MIT](LICENSE)。
