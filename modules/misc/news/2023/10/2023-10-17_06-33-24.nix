{ pkgs, ... }:

{
  time = "2023-10-17T06:33:24+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.darkman'.
  '';
}
