{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  labwc-rc-configuration = ./labwc-rc.nix;
  labwc-menu-configuration = ./labwc-menu.nix;
  labwc-autostart-configuration = ./labwc-autostart.nix;
  labwc-environment-configuration = ./labwc-environment.nix;
}
