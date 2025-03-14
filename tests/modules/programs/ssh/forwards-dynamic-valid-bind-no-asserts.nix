{ config, lib, ... }: {
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        dynamicBindPathNoPort = {
          dynamicForwards = [{
            # OK:
            address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          }];
        };

        dynamicBindAddressWithPort = {
          dynamicForwards = [{
            # OK:
            address = "127.0.0.1";
            port = 3000;
          }];
        };
      };
    };

    home.file.result.text = builtins.toJSON
      (map (a: a.message) (lib.filter (a: !a.assertion) config.assertions));

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./forwards-dynamic-valid-bind-no-asserts-expected.conf}
      assertFileContent home-files/result ${./no-assertions.json}
    '';
  };
}
