{ pkgs, ... }:

{
  time = "2021-08-31T18:44:26+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.betterlockscreen'.
  '';
}
