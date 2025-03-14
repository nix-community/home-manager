{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    networks = {
      "my-net" = {
        subnet = "192.168.1.0/24";
        gateway = "192.168.1.1";
        extraPodmanArgs = [ "--ipam-driver dhcp" ];
        extraConfig = {
          Network = {
            NetworkName = "my-net";
            Options = { isolate = "true"; };
            PodmanArgs = [ "--dns=192.168.55.1" "--log-level=debug" ];
          };
        };
      };

      "my-net-2" = {
        subnet = "192.168.2.0/24";
        gateway = "192.168.2.1";
        extraConfig = {
          Network = { NetworkName = "some-other-network-name"; };
        };
      };
    };
  };

  test.asserts.assertions.expected = [
    ''
      In 'my-net-2' config. Network.NetworkName: 'some-other-network-name' does not match expected type: value "my-net-2" (singular enum)''
  ];

  nmt.script = ''
    configPath=home-files/.config/systemd/user
    networkFile=$configPath/podman-my-net-network.service
    assertFileExists $networkFile

    networkFile=$(normalizeStorePaths $networkFile)

    assertFileContent $networkFile ${./network-expected.service}
  '';
}
