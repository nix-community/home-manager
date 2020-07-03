{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-alacritty" "";

      settings = {
        window.dimensions = {
          lines = 3;
          columns = 200;
        };

        key_bindings = [{
          key = "K";
          mods = "Control";
          chars = "\\x0c";
        }];
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/alacritty/alacritty.yml \
        ${./example-settings-expected.yml}
    '';
  };
}
