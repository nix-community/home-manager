{ config, ... }:

{
  time = "2024-03-14T07:22:59+00:00";
  condition = config.programs.rbw.enable;
  message = ''

    'programs.rbw.pinentry' has been simplified to only accept 'null' or
    a package.
  '';
}
