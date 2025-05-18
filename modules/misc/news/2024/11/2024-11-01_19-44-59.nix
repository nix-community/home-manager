{ pkgs, ... }:

{
  time = "2024-11-01T19:44:59+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.podman'.

    Podman is a daemonless container engine that lets you manage
    containers, pods, and images.

    This Home Manager module allows you to define containers that will run
    as systemd services.
  '';
}
