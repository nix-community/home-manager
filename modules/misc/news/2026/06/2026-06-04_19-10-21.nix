{ config, ... }:
{
  time = "2026-06-04T17:10:21+00:00";
  condition = config.programs.zellij.enable;
  message = ''
    Added support for Zellij plugins using `programs.zellij.plugins`.
  '';
}
