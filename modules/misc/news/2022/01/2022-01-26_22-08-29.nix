{ pkgs, ... }:

{
  time = "2022-01-26T22:08:29+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.kodi'.
  '';
}
