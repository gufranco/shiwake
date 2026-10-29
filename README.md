<div align="center">

<h1>shiwake</h1>

<strong>Sort the files of a folder into A to Z subfolders by their first letter, never moving one file over another.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/shiwake/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/shiwake/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/shiwake?style=flat-square&label=release)](https://github.com/gufranco/shiwake/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/shiwake?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> |
  <a href="#how-files-are-sorted">How files are sorted</a> |
  <a href="#development">Development</a>
</p>

</div>

One command, 67 tests, 7 shell modules, and nothing to install beyond a POSIX system. `shiwake` is 仕分け, Japanese for sorting things into their bins, the way a post office sorts letters. Its companions [kakikomi](https://github.com/gufranco/kakikomi), [kiyome](https://github.com/gufranco/kiyome) and [yakitsuke](https://github.com/gufranco/yakitsuke) write disks, wipe disks and burn Video CDs.

---

```console
$ shiwake ~/Downloads

Folder: /home/me/Downloads
Plan:   7 files into 5 folders named for their first letter

shiwake: warning: N/notes.txt already exists, so notes.txt stays where it is.
Sorted 6 of 7 files into 4 folders.
```

<a id="quick-start"></a>

## Quick start

### Prerequisites

| Tool | Why | Install |
|:-----|:----|:--------|
| `mkdir`, `mv` | Make the letter folders and move the files | Part of every Linux and macOS system |

### Install

```bash
brew install gufranco/tap/shiwake
```

Or from source:

```bash
git clone https://github.com/gufranco/shiwake.git
cd shiwake
make install
```

`make install` copies the tool, its man page and its bash, zsh and fish completions under `~/.local`, and puts `shiwake` in `~/.local/bin`; set `PREFIX` to change that. The Homebrew formula installs the same files.

### Verify

```console
$ shiwake doctor
mkdir              ok       /usr/bin/mkdir, uutils 0.10.0
mv                 ok       /usr/bin/mv, gnu 9.7
```

## Usage

| Command | Purpose |
|:--------|:--------|
| `shiwake [options] [folder]` | Sort the folder, or the current one when none is given |
| `shiwake` with no arguments | Ask for the folder, offering the current one, when run in a terminal |
| `shiwake doctor` | List the tools shiwake needs, with the flavor and version of each |
| `shiwake version`, `shiwake help` | Print the version or the full usage page |

| Option | Effect |
|:-------|:-------|
| `--dry-run` | List every move and change nothing |
| `--json` | Print the result as one JSON object, for scripts |

```bash
shiwake ~/Downloads              # sort the Downloads folder
shiwake --dry-run .              # see what sorting the current folder would do
```

`--` ends the options, so `shiwake -- -old` sorts a folder named `-old`. shiwake follows the shared command-line contract of its family, described in [FAMILY.md](FAMILY.md).

<a id="how-files-are-sorted"></a>

## How files are sorted

| First character of the name | Folder |
|:----------------------------|:-------|
| `a` to `z` or `A` to `Z` | That letter, in upper case: `apple` and `Avocado` both go to `A` |
| Anything else: a digit, a symbol, an accented or non-Latin letter | `#` |

- Only the top of the folder is sorted. Subfolders, including letter folders from an earlier run, stay as they are, and files join a letter folder that already exists.
- Symbolic links move like files and are never followed, so a link to a folder moves as a link.
- Hidden files, whose names start with a dot, and special files such as pipes stay where they are.
- A file is never moved over another. When `N/notes.txt` already exists, `notes.txt` stays and shiwake says so; the run still succeeds.
- When a file or a link already stands where a letter folder belongs, such as a file named `B`, the files for that letter stay where they are and the run ends with status 1.
- On a disk that ignores case, as macOS disks do by default, a file named `a` and the folder `A` would be the same name, so that file stays where it is. On a disk that tells case apart, it moves into `A`.
- Every name moves intact, including names with spaces, newlines, leading dashes or glob characters. Files are found with shell globs, and `mv` runs once per batch of up to 512 files, not once per file.

## Portability

Everything is POSIX `sh` with ShellCheck `-o all` at zero findings. The suites run on macOS under `/bin/sh`, the system's bash 3.2 and zsh, and Homebrew's current bash and zsh, and on Ubuntu under `dash`, `bash` and `zsh`.

Every run works on the five toolsets in common use: Linux with GNU or uutils coreutils, and macOS with the tools it ships, Homebrew's newer builds of them, or Homebrew's uutils tools. Every tool macOS ships that Homebrew also builds newer, bash and zsh included, is tested in both builds. CI runs the whole suite on each, and `shiwake doctor` names the flavor and version of `mkdir` and `mv`, such as `gnu 9.7`, `uutils 0.12.0` or `bsd`, so a bug report says which tools ran.

<a id="development"></a>

## Development

| Command | Description |
|:--------|:------------|
| `make fmt` | Formats every script with shfmt |
| `make lint` | shfmt, ShellCheck on every script, test and completion, and mandoc on the man page |
| `make test` | The `bats` tests under the system `sh` |
| `make test-all` | The same tests under every shell, both builds of bash and zsh included on macOS |
| `make test-linux` | The same tests in an Ubuntu container |
| `make coverage` | bashcov line coverage on this Mac and in the Ubuntu container, merged, with the 100% gate CI enforces |

The tests sort real folders on the real filesystem; only failures are injected, through small wrappers on `PATH`. Once CI passes on a push to `main`, semantic-release runs: a `feat` or `fix` commit publishes a release, updates `SHIWAKE_VERSION` in [`lib/core.sh`](lib/core.sh) and the CHANGELOG, and bumps the Homebrew formula.

## License

[MIT](LICENSE).
