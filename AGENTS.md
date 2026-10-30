# shiwake

Guidance for anyone, human or agent, changing shiwake. What shiwake is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything shiwake shares with the rest of the kodougu family, and it is the same in every member. This file holds only what is exclusive to shiwake, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into `FAMILY.md` instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bin/shiwake`](bin/shiwake) | The entry point: it clears inherited `SW_` variables, sources the modules and dispatches the command |
| [`lib/`](lib) | The modules. [`lib/state.sh`](lib/state.sh) declares every global, including the letter folders and their glob patterns |
| [`man/shiwake.1`](man/shiwake.1) | The man page |
| [`completions/`](completions) | bash, zsh and fish completions |
| [`test/`](test) | The `bats` suite, its helpers, the golden transcripts, the shell matrix runner and the Linux container script |
| [`scripts/`](scripts) | Coverage, the coverage gate, the Linux coverage run and the name check, which `make` runs |
| [`.github/scripts/`](.github/scripts) | The toolset helper and the release version stamp, which only CI and the release run |

## Names

- Globals carry `SW_`; function-scoped variables carry a per-function `sw_` prefix.
- Settings come from `SHIWAKE_<NAME>`, such as `SHIWAKE_BATCH`; test switches are `SHIWAKE_TERMINAL`, `SHIWAKE_TEST_SHELLS`, `SHIWAKE_TEST_RECORD` and `SHIWAKE_TEST_IMAGE`.
- Output goes through `sw_say`, `sw_error` and `sw_warning`.

## Behaviour

- shiwake has one job, so a bare `shiwake` on a terminal asks for the folder directly, offering the current one.
- Its options are `--dry-run` and `--json`, so the help page has a single `options:` section. `--json` reports the folder, the counts of files found, moved, kept and failed, and how many went into each letter folder.
- Moving files is not destructive, so it shows its summary block and starts without a typed confirmation.

## Domain rules

- A file is never moved over another. Every change to the move path keeps the test that proves an existing file survives.
- `mv` runs once per batch of `SW_BATCH` files.
- Tests sort real folders on the real filesystem.

## Release

- `SHIWAKE_VERSION` lives in [`lib/core.sh`](lib/core.sh).

## Gaps against FAMILY.md

None (as of 2026-10-29).
