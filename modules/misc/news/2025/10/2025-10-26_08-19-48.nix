{ pkgs, ... }:

{
  time = "2025-10-26T07:19:48+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `targets.genericLinux.gpu`

    This module provides integration of GPU drivers for non-NixOS systems. It is a
    simpler alternative to the existing `targets.genericLinux.nixGL` module. See the
    Home Manager user manual for more information.
  '';
}
