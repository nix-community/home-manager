{ pkgs, ... }:

{
  time = "2023-05-13T13:51:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.fuzzel'.
  '';
}
