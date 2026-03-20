{ pkgs, ... }:

{
  time = "2023-06-09T19:13:39+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.boxxy'.
  '';
}
