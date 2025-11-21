{ pkgs, ... }:

{
  time = "2021-08-16T21:59:02+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.git-sync'.
  '';
}
