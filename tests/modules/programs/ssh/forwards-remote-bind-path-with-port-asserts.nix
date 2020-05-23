{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        remoteBindPathWithPort = {
          remoteForwards = [{
            # OK:
            host.address = "127.0.0.1";
            host.port = 3000;

            # Error:
            bind.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
            bind.port = 3000;
          }];
        };
      };
    };

    home.file.result.text = builtins.toJSON
      (map (a: a.message) (filter (a: !a.assertion) config.assertions));

    nmt.script = ''
      assertFileContent $home_files/result ${
        ./forwards-paths-with-ports-error.json
      }
    '';
  };
}
