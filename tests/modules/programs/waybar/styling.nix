{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
      enable = true;
      style = ''
        * {
            border: none;
            border-radius: 0;
            font-family: Source Code Pro;
            font-weight: bold;
            color: #abb2bf;
            font-size: 18px;
            min-height: 0px;
        }
        window#waybar {
            background: #16191C;
            color: #aab2bf;
        }
        #window {
            padding: 0 0px;
        }
        #workspaces button:hover {
            box-shadow: inherit;
            text-shadow: inherit;
            background: #16191C;
            border: #16191C;
            padding: 0 3px;
        }
      '';
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/config
      assertFileContent \
        home-files/.config/waybar/style.css \
        ${./styling-expected.css}
    '';
  };
}
