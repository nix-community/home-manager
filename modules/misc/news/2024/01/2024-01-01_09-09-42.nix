{ pkgs, ... }:

{
  time = "2024-01-01T09:09:42+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.i3blocks'.
  '';
}
