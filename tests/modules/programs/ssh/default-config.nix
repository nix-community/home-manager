{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.ssh = { enable = true; };

    home.file.assertions.text = builtins.toJSON
      (map (a: a.message) (filter (a: !a.assertion) config.assertions));

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent home-files/.ssh/config ${./default-config-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
