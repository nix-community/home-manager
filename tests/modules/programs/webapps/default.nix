{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  webapps-basic = ./basic.nix;
  webapps-explicit-browser = ./explicit-browser.nix;
  webapps-auto-detect = ./auto-detect.nix;
  webapps-custom-options = ./custom-options.nix;
  webapps-gmail-example = ./gmail-example.nix;
  webapps-package-icons = ./package-icons.nix;
}
