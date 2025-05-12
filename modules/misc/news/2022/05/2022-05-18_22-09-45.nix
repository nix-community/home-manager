{ pkgs, ... }:

{
  time = "2022-05-18T22:09:45+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.mopidy'.
  '';
}
