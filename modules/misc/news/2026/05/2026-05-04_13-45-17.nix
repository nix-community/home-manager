{ config, pkgs, ... }:
{
  time = "2026-05-04T11:45:17+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    A new module is available: 'programs.brush'. This module is configured for bash
    compatibility and so will make use of existing bash dot files by default.
  '';
}
