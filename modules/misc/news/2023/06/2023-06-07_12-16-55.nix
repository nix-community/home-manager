{ pkgs, ... }:

{
  time = "2023-06-07T12:16:55+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.imv'.
  '';
}
