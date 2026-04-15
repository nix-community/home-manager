{
  lib,
  pkgs,
  ...
}:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  macos-terminal-basic-configuration = ./basic-configuration.nix;
}
