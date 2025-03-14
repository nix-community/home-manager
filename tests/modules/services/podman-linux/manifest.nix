{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    containers."my-container-1" = {
      description = "home-manager test";
      autoUpdate = "registry";
      autoStart = true;
      image = "docker.io/alpine:latest";
      entrypoint = "sleep 1000";
      environment = {
        "VAL_A" = "A";
        "VAL_B" = 2;
        "VAL_C" = false;
      };
    };
  };

  services.podman.containers."my-container-2" = {
    description = "home-manager test";
    autoUpdate = "registry";
    autoStart = true;
    image = "docker.io/alpine:latest";
    entrypoint = "sleep 1000";
    environment = {
      "VAL_A" = "B";
      "VAL_B" = 3;
      "VAL_C" = true;
    };
  };

  services.podman.networks."mynet-1" = {
    subnet = "192.168.1.0/24";
    gateway = "192.168.1.1";
  };
  services.podman.networks."mynet-2" = {
    subnet = "192.168.2.0/24";
    gateway = "192.168.2.1";
  };

  nmt.script = ''
    configPath=home-files/.config/podman
    containerManifest=$configPath/containers.manifest
    networkManifest=$configPath/networks.manifest

    assertFileExists $containerManifest
    assertFileExists $networkManifest

    assertFileContent $containerManifest ${
      builtins.toFile "containers.expected" ''
        my-container-1
        my-container-2
      ''
    }

    assertFileContent $networkManifest ${
      builtins.toFile "networks.expected" ''
        mynet-1
        mynet-2
      ''
    }
  '';
}
