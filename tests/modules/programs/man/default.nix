{ lib, pkgs, ... }:

{
  man-apropos = ./apropos.nix;
  man-no-manpath = ./no-manpath.nix;
  man-no-caches-without-package = ./no-caches-without-package.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  man-no-package-on-darwin = ./no-package-on-darwin.nix;
}
