{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.yambar = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        bar = {
          location = "top";
          height = 26;
          background = "00000066";

          right = [{ clock.content = [{ string.text = "{time}"; }]; }];
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/yambar/config.yml \
        ${./example-settings-expected.yml}
    '';
  };
}
