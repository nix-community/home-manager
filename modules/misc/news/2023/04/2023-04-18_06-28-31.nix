{ pkgs, ... }:

{
  time = "2023-04-18T06:28:31+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.batsignal'.
  '';
}
