{ pkgs, ... }:

{
  time = "2025-12-22T19:55:56+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    `targets.genericLinux.gpu` now supports GNU Shepherd.

    This module now supports the GNU Shepherd init system, primarily for
    compatibility with the GNU Guix distributuion.
    '';
}
