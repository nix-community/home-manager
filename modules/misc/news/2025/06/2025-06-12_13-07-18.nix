{ pkgs, ... }:
{
  time = "2025-06-12T17:07:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.ashell'.
  '';
}
