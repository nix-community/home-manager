{ pkgs, ... }:
{
  time = "2026-05-01T11:04:41+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.wiremix'.
  '';
}
