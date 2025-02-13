{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    containers."my-container" = {
      image = "docker.io/alpine:latest";
      network = [ "my-net" "externalnet" ];
    };
    networks."my-net" = {
      gateway = "192.168.123.1";
      subnet = "192.168.123.0/24";
    };
  };

  nmt.script = ''
    configPath=home-files/.config/systemd/user
    containerFile=$configPath/podman-my-container.service
    networkFile=$configPath/podman-my-net-network.service
    assertFileExists $containerFile
    assertFileExists $networkFile

    containerFile=$(normalizeStorePaths $containerFile)
    networkFile=$(normalizeStorePaths $networkFile)

    assertFileContent $containerFile ${./integration-container-expected.service}
    assertFileContent $networkFile ${./integration-network-expected.service}
  '';
}
