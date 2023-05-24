{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        dynamicBindPathWithPort = {
          dynamicForwards = [{
            # Error:
            address = "/run/user/1000/gnupg/S.gpg-agent.extra";
            port = 3000;
          }];
        };
      };
    };

    test.asserts.assertions.expected = [ "Forwarded paths cannot have ports." ];
  };
}
