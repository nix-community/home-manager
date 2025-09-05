{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  i3status-rust-with-default = ./with-default.nix;
  i3status-rust-with-custom = ./with-custom.nix;
  i3status-rust-with-extra-settings = ./with-extra-settings.nix;
  i3status-rust-with-multiple-bars = ./with-multiple-bars.nix;
  i3status-rust-with-version-02xx = ./with-version-02xx.nix;
  i3status-rust-with-version-0311 = ./with-version-0311.nix;
}
