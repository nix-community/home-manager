{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  local-ai-enabled = ./enabled.nix;
  local-ai-enabled-with-environment = ./enabled-with-environment.nix;
}
