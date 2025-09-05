{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  lxqt-policykit-agent-basic-configuration = ./basic-configuration.nix;
}
