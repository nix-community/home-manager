{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpd-mpris-configuration-basic = ./configuration-basic.nix;
  mpd-mpris-configuration-with-password = ./configuration-with-password.nix;
  mpd-mpris-configuration-with-password-path = ./configuration-with-password-path.nix;
  mpd-mpris-configuration-with-instance-name = ./configuration-with-instance-name.nix;
  mpd-mpris-configuration-with-renamed-options = ./configuration-with-renamed-options.nix;
}
