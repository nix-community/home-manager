{ config, lib, ... }:
{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          compression = false;
          addKeysToAgent = "no";
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";

          identitiesOnly = true;
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };

        "tor-*" = lib.hm.dag.entryBefore [ "*-screen" ] {
          proxyCommand = "socat STDIO SOCKS4A:127.0.0.1:%h:%p,socksport=9050";
          addressFamily = "inet";
          compression = true;
        };

        "*-screen" = lib.hm.dag.entryAfter [ "*" ] {
          extraOptions = {
            RemoteCommand = "screen -RD ssh";
            RequestTTY = "yes";
          };
        };
      };
    };

    home.file.assertions.text = builtins.toJSON (
      map (a: a.message) (lib.filter (a: !a.assertion) config.assertions)
    );

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./match-blocks-attrs-glob-order-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
