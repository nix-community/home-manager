{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        abc = {
          identityFile = null;
          proxyJump = "jump-host";
        };

        xyz = {
          identityFile = "file";
          serverAliveInterval = 60;
          localForwards = [
            {
              bind.port = 8080;
              host.address = "10.0.0.1";
              host.port = 80;
            }
          ];
        };

        "* !github.com" = {
          identityFile = ["file1" "file2"];
          port = 516;
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./match-blocks-attrs-expected.conf}
    '';
  };
}
