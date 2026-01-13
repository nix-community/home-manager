# Common commands
#
# Contributing manual:
# - https://nix-community.github.io/home-manager/#ch-contributing

# List tests matching a pattern `pattern`
list *pattern:
  nix run .#tests -- -l {{pattern}}

# Run all tests matching a pattern `pattern`
test *pattern:
  nix run .#tests -- {{pattern}}

# Run integration tests
integration_tests:
  nix run .#tests -- -t -l
