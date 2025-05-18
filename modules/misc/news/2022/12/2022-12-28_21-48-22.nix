{ pkgs, ... }:

{
  time = "2022-12-28T21:48:22+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.clipman'.
  '';
}
