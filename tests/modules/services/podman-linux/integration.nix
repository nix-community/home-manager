{ pkgs, ... }:
let
  containerFile = pkgs.writeTextFile {
    name = "Containerfile";
    text = ''
      FROM docker.io/alpine:latest
    '';
  };
in {
  services.podman = {
    enable = true;
    builds."my-bld" = { file = "${containerFile}"; };
    containers = {
      "my-container" = {
        image = "my-img";
        network = [ "my-net" "externalnet" ];
        volumes = [ "my-vol:/data" ];
      };
      "my-container-bld" = { image = "my-bld"; };
    };
    images."my-img" = { image = "docker.io/alpine:latest"; };
    networks."my-net" = {
      gateway = "192.168.123.1";
      subnet = "192.168.123.0/24";
    };
    volumes."my-vol" = {
      device = "tmpfs";
      preserve = false;
      type = "tmpfs";
    };
  };

  nmt.script = ''
    configPath=home-files/.config/systemd/user
    buildFile=$configPath/podman-my-bld-build.service
    containerFile=$configPath/podman-my-container.service
    containerBldFile=$configPath/podman-my-container-bld.service
    imageFile=$configPath/podman-my-img-image.service
    networkFile=$configPath/podman-my-net-network.service
    volumeFile=$configPath/podman-my-vol-volume.service
    assertFileExists $buildFile
    assertFileExists $containerFile
    assertFileExists $containerBldFile
    assertFileExists $imageFile
    assertFileExists $networkFile
    assertFileExists $volumeFile

    buildFile=$(normalizeStorePaths $buildFile)
    containerFile=$(normalizeStorePaths $containerFile)
    containerBldFile=$(normalizeStorePaths $containerBldFile)
    imageFile=$(normalizeStorePaths $imageFile)
    networkFile=$(normalizeStorePaths $networkFile)
    volumeFile=$(normalizeStorePaths $volumeFile)

    assertFileContent $buildFile ${./integration-build-expected.service}
    assertFileContent $containerFile ${./integration-container-expected.service}
    assertFileContent $containerBldFile ${
      ./integration-container-bld-expected.service
    }
    assertFileContent $imageFile ${./integration-image-expected.service}
    assertFileContent $networkFile ${./integration-network-expected.service}
    assertFileContent $volumeFile ${./integration-volume-expected.service}
  '';
}
