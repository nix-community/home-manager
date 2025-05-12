{ pkgs, ... }:

{
  time = "2022-07-13T13:28:54+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.librewolf'.
  '';
}
