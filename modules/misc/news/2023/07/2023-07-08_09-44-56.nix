{ pkgs, ... }:

{
  time = "2023-07-08T09:44:56+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.swayosd'
  '';
}
