{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  herbstluftwm-simple-config = ./herbstluftwm-simple-config.nix;
  herbstluftwm-no-tags = ./herbstluftwm-no-tags.nix;
}
