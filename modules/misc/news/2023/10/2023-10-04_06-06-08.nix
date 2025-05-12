{ config, ... }:

{
  time = "2023-10-04T06:06:08+00:00";
  condition = config.programs.zsh.enable;
  message = ''

    A new module is available: 'programs.zsh.zsh-abbr'
  '';
}
