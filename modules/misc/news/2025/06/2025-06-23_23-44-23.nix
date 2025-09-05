{ pkgs, ... }:
{
  time = "2025-06-24T03:44:23+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.quickshell'.
  '';
}
