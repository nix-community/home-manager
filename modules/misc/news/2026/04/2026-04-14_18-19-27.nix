{ config, pkgs, ... }:
{
  time = "2026-04-14T12:49:27+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    Added new option for yazi: programs.yazi.vfs

    Yazi has a vfs.toml in it's config directory to manage
    virtual file systems. The conifguration can now be managed with
    programs.yazi.vfs
  '';
}
