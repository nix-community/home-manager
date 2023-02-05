{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "22.11";

    programs.wlogout = {
      package = config.lib.test.mkStubPackage { outPath = "@wlogout@"; };
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
        window {
            background: #16191C;
            color: #aab2bf;
        }
        #window {
            padding: 0 0px;
        }
      '';
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/wlogout/layout
      assertFileContent \
        home-files/.config/wlogout/style.css \
        ${./styling-expected.css}
    '';
  };
}
