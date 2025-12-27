{
  config,
  lib,
  pkgs,
  ...
}:
{
  time = "2025-11-04T15:44:03+00:00";
  condition = true;
  message = ''
    The 'services.podman' module now supports Darwin (macOS) with declarative
    machine management.

    On Darwin, podman requires running containers inside a virtual machine.
    The new configuration options allow you to declaratively manage podman
    machines with automatic creation, configuration, and startup.

    By default, a machine named 'podman-machine-default' will be created
    automatically. You can customize machines or disable the default with:

      services.podman.useDefaultMachine = false;
      services.podman.machines = {
        "my-machine" = {
          cpus = 4;
          memory = 8192;
          diskSize = 100;
          autoStart = true;
        };
      };

    The module includes a launchd-based watchdog service that automatically
    starts configured machines on login and keeps them running.
  '';
}
