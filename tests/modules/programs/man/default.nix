{ lib, pkgs, ... }:

{
  man-apropos = ./apropos.nix;
  man-assertion = ./assertion.nix;
  man-disabled-man-db = ./disabled-man-db.nix;
  man-disabled-mandoc = ./disabled-mandoc.nix;
  man-extra-config = ./extra-config.nix;
  man-extra-config-and-no-cache = ./extra-config-and-no-cache.nix;
  man-mandoc = ./mandoc.nix;
  man-no-manpath = ./no-manpath.nix;
  man-no-caches-without-package = ./no-caches-without-package.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  man-no-package-on-darwin = ./no-package-on-darwin.nix;
}
