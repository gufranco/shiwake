SHELL := /bin/sh
PREFIX ?= $(HOME)/.local

.PHONY: help lint test test-all coverage check install

help:
	@echo "targets:"
	@echo "  lint        shellcheck -o all and mandoc at zero findings"
	@echo "  test        bats suites under the system sh"
	@echo "  test-all    bats suites under every installed shell"
	@echo "  coverage    bashcov line coverage with a 100% gate"
	@echo "  check       lint and test"
	@echo "  install     install the tool, man page and completions under PREFIX (default ~/.local)"

lint:
	shellcheck -x -s sh -o all bin/shiwake lib/*.sh scripts/*.sh test/call.sh test/run-matrix.sh
	sh scripts/check-names.sh
	shellcheck -x -o all test/*.bash test/*.bats
	shellcheck -s bash -o all completions/shiwake.bash
	mandoc -T lint man/shiwake.1

test:
	SW_SHELLS=sh sh test/run-matrix.sh

test-all:
	sh test/run-matrix.sh

coverage:
	sh scripts/coverage.sh 100

check: lint test

install:
	mkdir -p "$(PREFIX)/share/shiwake" "$(PREFIX)/bin" "$(PREFIX)/share/man/man1" "$(PREFIX)/share/bash-completion/completions" "$(PREFIX)/share/zsh/site-functions" "$(PREFIX)/share/fish/vendor_completions.d"
	cp -R bin lib "$(PREFIX)/share/shiwake/"
	cp -f man/shiwake.1 "$(PREFIX)/share/man/man1/shiwake.1"
	cp -f completions/shiwake.bash "$(PREFIX)/share/bash-completion/completions/shiwake"
	cp -f completions/_shiwake "$(PREFIX)/share/zsh/site-functions/_shiwake"
	cp -f completions/shiwake.fish "$(PREFIX)/share/fish/vendor_completions.d/shiwake.fish"
	printf '#!/bin/sh\nexec "%s/share/shiwake/bin/shiwake" "$$@"\n' "$(PREFIX)" > "$(PREFIX)/bin/shiwake"
	chmod 755 "$(PREFIX)/bin/shiwake"
