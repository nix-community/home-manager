{ config, pkgs, lib, ... }:

lib.mkIf config.test.enableBig {
  virtualisation.podman = {
    enable = true;
    enableDockerAlias = true;
    enableDockerSocket = true;
  };

  nmt.script = ''
    assertFileIsExecutable home-path/bin/docker
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh "DOCKER_HOST"
  '';
}
