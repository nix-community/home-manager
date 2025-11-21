{ pkgs, ... }:

{
  time = "2024-03-28T17:02:19+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.amberol'.
  '';
}
