{ pkgs, ... }:

{
  time = "2023-02-22T22:16:37+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.avizo'.
  '';
}
