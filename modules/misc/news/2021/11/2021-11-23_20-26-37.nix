{ config, ... }:

{
  time = "2021-11-23T20:26:37+00:00";
  condition = config.programs.taskwarrior.enable;
  message = ''

    Taskwarrior version 2.6.0 respects XDG Specification for the config
    file now. Option 'programs.taskwarrior.config' and friends now
    generate the config file at '$XDG_CONFIG_HOME/task/taskrc' instead of
    '~/.taskrc'.
  '';
}
