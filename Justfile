# Common commands
#
# Contributing manual:
# - https://nix-community.github.io/home-manager/#ch-contributing


# List tests matching a pattern `PAT`
list PAT:
  nix run .#tests -- -l {{PAT}}

# List all available tests
list_all:
  nix run .#tests -- -l

# Run all tests matching a pattern `PAT`
test_pat PAT:
  nix run .#tests -- {{PAT}}

# Run a specific test `TEST`
test TEST:
  nix run .#tests -- {{TEST}}

# Run integration tests
integration_tests:
  nix run .#tests -- -t -l
