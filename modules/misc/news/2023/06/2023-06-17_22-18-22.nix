{ config, ... }:

{
  time = "2023-06-17T22:18:22+00:00";
  condition = config.programs.zsh.enable;
  message = ''

    A new module is available: 'programs.zsh.antidote'
  '';
}
