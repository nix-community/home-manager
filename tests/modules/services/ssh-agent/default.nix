{
  lib,
  pkgs,
  ...
}:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ssh-agent-basic-service = ./basic-service.nix;
  ssh-agent-timeout-service = ./timeout-service.nix;
}
