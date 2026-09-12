{ config, pkgs, ... }:

{
  time = "2026-09-12T02:05:25+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux && config.services.grobi.enable;
  message = ''
    Grobi now supports complete freeform JSON configuration through
    `services.grobi.settings`, including the native `on_failure` commands.
    See the 26.11 release notes for the renamed options.
  '';
}
