.PHONY: all all-tests test test-install format
NIXPKGS_REV := 40f55bb03a0142e7d5e523939732737c6053f208
# NIX_PATH := nixpkgs=https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_REV}.tar.gz
NIX_PATH := nixpkgs=https://github.com/teto/nixpkgs/archive/${NIXPKGS_REV}.tar.gz

all: all-tests test-install

all-tests:
	$(MAKE) test TEST=all

test:
ifndef TEST
	$(error Use 'make test TEST=<test_name>' to run desired test)
endif
	nix-shell --pure tests -I ${NIX_PATH} -A run.${TEST}

test-install:
	HOME=$(shell mktemp -d) NIX_PATH=${NIX_PATH} nix-shell . -A install

format:
	nix-shell -p treefmt nixfmt deadnix keep-sorted nixf-diagnose --run "treefmt --config-file ./treefmt.toml"
