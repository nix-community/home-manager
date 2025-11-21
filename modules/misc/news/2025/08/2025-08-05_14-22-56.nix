{ config, ... }:
{
  time = "2025-08-05T19:03:10+00:00";
  condition = config.programs.zsh.enable;
  message = ''
    The 'programs.zsh' module now supports autoloadable site functions.

    A new 'siteFunctions' option allows defining custom shell functions that
    will be automatically loaded by zsh, providing a clean way to organize
    and distribute reusable shell functionality.
  '';
}
