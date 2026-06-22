{ config, ... }:
{
  time = "2026-03-12T13:04:00+00:00";
  condition = config.programs.neovim.enable;
  message = ''
    The ruby provider is now disabled by default since the overwhelming majority of users do not use it.
    Set `programs.neovim.withRuby = true;` to restore the previous behavior.
  '';
}
