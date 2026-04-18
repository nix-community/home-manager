{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wlr-which-key-empty-config = ./empty-config.nix;
  wlr-which-key-example-config = ./example-config.nix;
  wlr-which-key-example-extramenu = ./example-extramenu.nix;
}
