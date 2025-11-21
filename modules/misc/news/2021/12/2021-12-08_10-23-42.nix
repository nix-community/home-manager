{ config, ... }:

{
  time = "2021-12-08T10:23:42+00:00";
  condition = config.programs.less.enable;
  message = ''

    The 'lesskey' configuration file is now stored under
    '$XDG_CONFIG_HOME/lesskey' since it is fully supported upstream
    starting from v596.
  '';
}
