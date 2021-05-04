{ config, lib, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;

      config = {
        bars = [{
          fonts = {
            names = [ "FontAwesome" "Iosevka" ];
            size = 11.5;
          };
        }];
        fonts = {
          names = [ "DejaVuSansMono" "Terminus" ];
          style = "Bold Semi-Condensed";
          size = 13.5;
        };
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        dmenu = super.dmenu // { outPath = "@dmenu@"; };

        i3 = super.writeScriptBin "i3" "" // { outPath = "@i3@"; };

        i3-gaps = super.writeScriptBin "i3" "" // { outPath = "@i3-gaps@"; };

        i3status = super.i3status // { outPath = "@i3status@"; };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${./i3-fonts-expected.conf}
    '';
  };
}
