{ config, pkgs, lib, ... }:

{
  config = {
    services.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket = true;
    };
    nmt.script = ''
      assertFileIsExecutable home-path/bin/docker
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh "DOCKER_HOST"
    '';
  };
}
