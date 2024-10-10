{ ... }:

{
  config = {
    services.podman.containers."my-container" = {
      description = "home-manager test";
      autoupdate = "registry";
      autostart = true;
      image = "docker.io/alpine:latest";
      entrypoint = "sleep 1000";
      environment = {
        "VAL_A" = "A";
        "VAL_B" = 2;
        "VAL_C" = false;
      };
      ports = [ "8080:80" ];
      volumes = [ "/tmp:/tmp" ];
      devices = [ "/dev/null:/dev/null" ];

      networks = [ "mynet" ];
      networkAlias = "test-alias";

      extraOptions = [ "--security-opt=no-new-privileges" ];
      extraContainerConfig = { ReadOnlyTmpfs = true; };
      serviceConfig = { Restart = "on-failure"; };
      unitConfig = { Before = [ "fake.target" ]; };
    };

    nmt.script = ''
      configPath=home-files/.config/systemd/user
      containerFile=$configPath/podman-my-container.service
      assertFileExists $containerFile

      assertFileContains $containerFile \
        "my-container.container"
      assertFileContains $containerFile \
        "Description=home-manager test"
      assertFileContains $containerFile \
        "AutoUpdate=registry"
      assertFileContains $containerFile \
        "Image=docker.io/alpine:latest"
      assertFileContains $containerFile \
        "PodmanArgs=--network-alias test-alias --entrypoint sleep 1000 --security-opt=no-new-privileges"
      assertFileContains $containerFile \
        "Environment=VAL_A=A VAL_B=2 VAL_C=false"
      assertFileContains $containerFile \
        "PublishPort=8080:80"
      assertFileContains $containerFile \
        "Volume=/tmp:/tmp"
      assertFileContains $containerFile \
        "AddDevice=/dev/null:/dev/null"
      assertFileContains $containerFile \
        "Network=mynet"
      assertFileContains $containerFile \
        "Requires=podman-mynet-network.service"
      assertFileContains $containerFile \
        "After=network.target podman-mynet-network.service"
      assertFileContains $containerFile \
        "ReadOnlyTmpfs=true"
      assertFileContains $containerFile \
        "Restart=on-failure"
      assertFileContains $containerFile \
        "Before=fake.target"
      assertFileContains $containerFile \
        "WantedBy=multi-user.target default.target"
      assertFileContains $containerFile \
        "Label=nix.home-manager.managed=true"
    '';
  };
}
