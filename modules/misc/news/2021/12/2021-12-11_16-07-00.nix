{ pkgs, ... }:

{
  time = "2021-12-11T16:07:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.gromit-mpx'.
  '';
}
