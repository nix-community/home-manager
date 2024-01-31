{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty = {
      enable = true;
      package = config.lib.test.mkStubPackage { version = "0.13.0"; };

      settings = {
        window.dimensions = {
          lines = 3;
          columns = 200;
        };

        keyboard.bindings = [{
          key = "K";
          mods = "Control";
          chars = "\\x0c";
        }];
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/alacritty/alacritty.toml \
        ${./example-settings-expected.toml}
    '';
  };
}
