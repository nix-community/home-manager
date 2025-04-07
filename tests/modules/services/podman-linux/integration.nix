{ pkgs, ... }:

{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    builds."my-bld" = {
      file =
        let
          containerFile = pkgs.writeTextFile {
            name = "Containerfile";
            text = ''
              FROM docker.io/alpine:latest
            '';
          };
        in
        "${containerFile}";
    };
    containers = {
      "my-container" = {
        image = "my-img.image";
        network = [
          "my-app.network"
          "externalnet"
        ];
        volumes = [ "my-app.volume:/data" ];
      };
      "my-container-bld" = {
        image = "my-bld.build";
      };
    };
    images."my-img" = {
      image = "docker.io/alpine:latest";
    };
    networks."my-app" = {
      gateway = "192.168.123.1";
      subnet = "192.168.123.0/24";
    };
    volumes."my-app" = {
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
    networkFile=$configPath/podman-my-app-network.service
    volumeFile=$configPath/podman-my-app-volume.service
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
    assertFileContent $containerBldFile ${./integration-container-bld-expected.service}
    assertFileContent $imageFile ${./integration-image-expected.service}
    assertFileContent $networkFile ${./integration-network-expected.service}
    assertFileContent $volumeFile ${./integration-volume-expected.service}
  '';
}
