.PHONY: all all-tests test format
NIXPKGS_REV := nixpkgs-unstable
NIX_PATH := nixpkgs=https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_REV}.tar.gz

all: all-tests

all-tests:
	$(MAKE) test TEST=all

test:
ifndef TEST
	$(error Use 'make test TEST=<test_name>' to run desired test)
endif
	nix-shell --pure tests -I ${NIX_PATH} -A run.${TEST}

format:
	./format
