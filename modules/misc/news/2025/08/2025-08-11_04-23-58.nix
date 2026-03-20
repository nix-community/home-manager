{ pkgs, ... }:
{
  time = "2025-08-11T04:23:58+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new service is available: 'services.walker'.

    Walker is a fast, customizable application launcher. It provides
    a themeable interface for launching applications, running commands, and more.
  '';
}
