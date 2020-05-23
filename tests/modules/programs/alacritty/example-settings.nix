{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty = {
      enable = true;

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

    nixpkgs.overlays = [
      (self: super: { alacritty = pkgs.writeScriptBin "dummy-alacritty" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        $home_files/.config/alacritty/alacritty.yml \
        ${./example-settings-expected.yml}
    '';
  };
}
