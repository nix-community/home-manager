{ pkgs, ... }:

{
  time = "2025-03-21T03:19:14+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.distrobox'.

    Distrobox is a tool that uses podman or docker to create containers using
    the Linux distribution of your choice. It allows you to use the package
    manager of other distributions to install applications that aren't available
    in NixOS, and integrates those applications with your host system. The module
    enables configuration of container definitions and distrobox settings.
  '';
}
