{ pkgs, ... }:

{
  time = "2022-01-03T10:34:45+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.swayidle'.
  '';
}
