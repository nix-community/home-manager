{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    containers = {
      "my-container" = {
        description = "home-manager test";
        autoStart = true;
        autoUpdate = "registry";
        devices = [ "/dev/null:/dev/null" ];
        entrypoint = "/sleep.sh";
        environment = {
          "VAL_A" = "A";
          "VAL_B" = 2;
          "VAL_C" = false;
        };
        extraPodmanArgs = [ "--security-opt=no-new-privileges" ];
        extraConfig = {
          Container = {
            ReadOnlyTmpfs = true;
            NetworkAlias = "test-alias-2";
          };
          Service.Restart = "on-failure";
          Unit.Before = "fake.target";
        };
        image = "docker.io/alpine:latest";
        # Should not generate Requires/After for network because there is no
        # services.podman.networks.mynet.
        network = "mynet";
        networkAlias = [ "test-alias-1" ];
        ports = [ "8080:80" ];
        volumes = [ "/tmp:/tmp" ];
      };

      "my-container-2" = {
        image = "docker.io/alpine:latest";
        extraConfig = {
          Container.ContainerName = "some-other-container-name";
        };
      };
    };
  };

  test.asserts.assertions.expected = [
    ''
      In 'my-container-2' config. Container.ContainerName: 'some-other-container-name' does not match expected type: value "my-container-2" (singular enum)''
  ];

  nmt.script = ''
    configPath=home-files/.config/systemd/user
    containerFile=$configPath/podman-my-container.service

    assertFileExists $containerFile

    containerFile=$(normalizeStorePaths $containerFile)

    assertFileContent $containerFile ${./container-expected.service}
  '';
}
