{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  davmail-custom-settings = ./custom-settings.nix;
  davmail-imitateOutlook = ./imitateOutlook.nix;
}
