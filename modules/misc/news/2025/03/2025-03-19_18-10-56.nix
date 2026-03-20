{ config, ... }:

{
  time = "2025-03-19T18:10:56+00:00";
  condition = config.services.easyeffects.enable;
  message = ''
    The Easyeffects module now supports adding json formatted presets
    under '$XDG_CONFIG_HOME/easyeffects/{input,output}/'.
  '';
}
