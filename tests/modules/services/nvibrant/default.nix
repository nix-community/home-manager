{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  nvibrant-dithering = ./dithering.nix;
  nvibrant-merged = ./merged.nix;
  nvibrant-multigpu = ./multigpu.nix;
  nvibrant-vibrancy = ./vibrancy.nix;
}
