{ ... }:

{
  config = {
    services.podman.networks.mynet = {
      subnet = "192.168.1.0/24";
      gateway = "192.168.1.1";
      extraNetworkConfig = {
        Options = "isolate=true";
        PodmanArgs = [ "--dns=192.168.55.1" "--log-level=debug" ];
      };
    };

    nmt.script = ''
      configPath=home-files/.config/systemd/user
      networkFile=$configPath/podman-mynet-network.service
      assertFileExists $networkFile

      assertFileContains $networkFile \
        "mynet.network"
      assertFileContains $networkFile \
        "Subnet=192.168.1.0/24"
      assertFileContains $networkFile \
        "Gateway=192.168.1.1"
      assertFileContains $networkFile \
        "PodmanArgs=--dns=192.168.55.1 --log-level=debug"
      assertFileContains $networkFile \
        "Options=isolate=true"
      assertFileContains $networkFile \
        "NetworkName=mynet"
      assertFileContains $networkFile \
        "WantedBy=multi-user.target default.target"
      assertFileContains $networkFile \
        "RemainAfterExit=yes"
      assertFileContains $networkFile \
        "Label=nix.home-manager.managed=true"
    '';
  };
}
