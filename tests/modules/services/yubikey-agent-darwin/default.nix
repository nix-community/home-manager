{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  yubikey-agent-darwin = ./service.nix;
}
