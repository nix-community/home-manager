{ config, pkgs, lib, ... }:

{
  config = {
    services.podman.enable = true;
    nmt.script = ''
      servicePath=home-files/.config/systemd/user

      assertFileExists $servicePath/podman.service $servicePath/podman.socket
    '';
  };
}
