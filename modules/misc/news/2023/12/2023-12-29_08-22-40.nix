{ pkgs, ... }:

{
  time = "2023-12-29T08:22:40+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.bemenu'.
  '';
}
