{ config, pkgs, ... }:
{
  time = "2026-04-14T09:20:21+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    PLACEHOLDER
  '';
}
