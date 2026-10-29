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
| [`test/`](test) | The `bats` suite, its helpers and the shell matrix runner |
| [`scripts/`](scripts) | Coverage, the coverage gate, the name check, the toolset helper and the release version stamp |

## Names

- Globals carry `SW_`; function-scoped variables carry a per-function `sw_` prefix.
- Settings come from `SHIWAKE_<NAME>`; test switches are `SHIWAKE_TERMINAL` and `SHIWAKE_TEST_SHELLS`.
- Output goes through `sw_say`, `sw_error` and `sw_warning`.

## Behaviour

- shiwake has one job, so a bare `shiwake` on a terminal asks for the folder directly, offering the current one.
- Its only option is `--dry-run`, so the help page has a single `options:` section.
- Moving files is not destructive, so it shows its summary block and starts without a typed confirmation.

## Domain rules

- A file is never moved over another. Every change to the move path keeps the test that proves an existing file survives.
- `mv` runs once per batch of `SW_BATCH` files.
- Tests sort real folders on the real filesystem.

## Release

- `SHIWAKE_VERSION` lives in [`lib/core.sh`](lib/core.sh).

## Gaps against FAMILY.md

As of 2026-10-29, closed in the change that removes each line:

- No `make test-linux`, `test/linux-container.sh` or merged local coverage.
- No golden transcripts.
- No `--json` for the moves a run made.
