{ pkgs, config, ... }:
{
  time = "2026-01-20T12:27:29+00:00";
  condition = config.programs.eww.configDir != null && pkgs.hostPlatform.isLinux;
  message = ''
    The option 'programs.eww.configDir' has been deprecated, please use 'programs.eww.yuckConfig' and 'programs.eww.scssConfig' instead.
  '';
}
