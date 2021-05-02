{ config, lib, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;

      config = {
        bars = [{ fonts = [ "FontAwesome" "Iosevka 11.500000" ]; }];
        fonts = [ "DejaVuSansMono" "Terminus Bold Semi-Condensed 13.500000" ];
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

    test.asserts.warnings.expected = [
      "Specifying i3.config.fonts as a list is deprecated. Use the attrset version instead."
      "Specifying i3.config.bars[].fonts as a list is deprecated. Use the attrset version instead."
    ];
  };
}
