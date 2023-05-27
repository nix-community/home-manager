{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        abc = { port = 2222; };

        xyz = {
          match = "host xyz canonical";
          port = 2223;
        };

        "* !github.com" = { port = 516; };
      };
    };

    home.file.assertions.text = builtins.toJSON
      (map (a: a.message) (filter (a: !a.assertion) config.assertions));

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./match-blocks-match-and-hosts-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
