{ ... }:

{
  config = {
    services.podman = {
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

      assertFileContains $containerFile \
        "After=podman-my-net-network.service"
      assertFileContains $containerFile \
        "Requires=podman-my-net-network.service"
      assertFileContains $containerFile \
        "Network=my-net"
      assertFileContains $containerFile \
        "Network=externalnet"
      assertFileNotRegex $containerFile \
        "After=externalnet"
      assertFileNotRegex $containerFile \
        "Requires=externalnet"
      assertFileNotRegex $containerFile \
        "PublishPort=.*$"
      assertFileContains $networkFile \
        "Subnet=192.168.123.0/24"
    '';
  };
}
