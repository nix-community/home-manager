{ pkgs, ... }:

{
  time = "2024-03-15T08:39:52+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.activitywatch'.
  '';
}
