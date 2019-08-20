{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        localHostPathWithPort = {
          localForwards = [
            {
              # OK:
              bind.address = "127.0.0.1";
              bind.port = 3000;

              # Error:
              host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
              host.port = 3000;
            }
          ];
        };
      };
    };

    home.file.result.text =
      builtins.toJSON
      (map (a: a.message)
      (filter (a: !a.assertion)
        config.assertions));

    nmt.script = ''
      assertFileContent home-files/result ${./forwards-paths-with-ports-error.json}
    '';
  };
}
