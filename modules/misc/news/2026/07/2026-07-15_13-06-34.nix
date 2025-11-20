_:
{
  time = "2026-07-15T18:06:34+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    A lorri daemon for darwin is now available.

    Enable it with: `services.lorri.enable = true`
  '';
}
