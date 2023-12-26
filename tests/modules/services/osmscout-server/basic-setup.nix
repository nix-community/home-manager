{ config, ... }:

{
  services.osmscout-server = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@osmscout-server@"; };
    network = {
      startWhenNeeded = true;
      listenAddress = "0.0.0.0";
      port = 55555;
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/osmscout-server.service \
      ${
        builtins.toFile "osmscout-server.service" ''
          [Service]
          ExecStart='@osmscout-server@/bin/osmscout-server' --systemd --quiet

          [Unit]
          Description=OSM Scout Server
        ''
      }
    assertFileContent \
      home-files/.config/systemd/user/osmscout-server.socket \
      ${
        builtins.toFile "osmscout-server.socket" ''
          [Install]
          WantedBy=sockets.target

          [Socket]
          ListenStream=0.0.0.0:55555
          TriggerLimitBurst=1
          TriggerLimitIntervalSec=60s

          [Unit]
          Description=OSM Scout Server Socket
        ''
      }
  '';
}
