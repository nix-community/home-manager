{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  screen-locker-basic-configuration = ./basic-configuration.nix;
  screen-locker-no-xautolock = ./no-xautolock.nix;
  screen-locker-moved-options = ./moved-options.nix;
}
