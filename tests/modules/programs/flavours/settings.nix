{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.flavours = {
      enable = true;

      settings = {
        shell = "bash -c '{}'";
        item = [
          {
            file = "~/.config/sway/config";
            template = "sway";
            subtemplate = "colors";
            hook = "swaymsg reload";
            light = false;
          }
          {
            file = "~/.config/waybar/colors.css";
            template = "waybar";
            rewrite = true;
          }
          {
            file = "~/.config/beautifuldiscord/style.css";
            template = "styles";
            subtemplate = "css-variables";
            start = "/* Start Flavours */";
            end = "/* End Flavours */";
          }
        ];
      };
    };

    nixpkgs.overlays = [
      (self: super: { flavours = pkgs.writeScriptBin "dummy-flavours" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/flavours/config.toml \
        ${./settings-expected.toml}
    '';
  };
}
