{ config, pkgs, ... }:
{
  time = "2026-03-20T21:09:32+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    PLACEHOLDER
  '';
}
