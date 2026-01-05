{ config, ... }:
{
  time = "2025-12-27T19:00:00+00:00";
  condition = config.programs.zsh.enable;

  message = ''
    The default value of `programs.zsh.dotDir` has changed.

    When `home.stateVersion` is set to "26.05" or later, and `xdg.enable` is
    `true` (the default), `programs.zsh.dotDir` now defaults to
    `''${config.xdg.configHome}/zsh`. Previously, it defaulted to the home
    directory.

    This means your Zsh configuration files (`.zshrc`, `.zshenv`, etc.) will be
    moved to `~/.config/zsh` (or your configured XDG config home).

    If you prefer the old behavior, you can explicitly set:
    `programs.zsh.dotDir = config.home.homeDirectory;`
  '';
}
