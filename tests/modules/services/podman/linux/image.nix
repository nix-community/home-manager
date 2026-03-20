{ config, lib, ... }:
{
  imports = [ ./podman-stubs.nix ];
  config = lib.mkIf config.test.enableLegacyIfd {
    services.podman = {
      enable = true;
      images = {
        "my-img" = {
          image = "docker.io/alpine:latest";
        };
      };
    };

    nmt.script = ''
      configPath=home-files/.config/systemd/user
      imageFile=$configPath/podman-my-img-image.service
      assertFileExists $imageFile

      imageFile=$(normalizeStorePaths $imageFile)

      assertFileContent $imageFile ${./image-expected.service}
    '';
  };
}
