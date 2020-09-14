{ config, lib, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;

      config.focus.followMouse = false;
    };

    nixpkgs.overlays = [
      (self: super: {
        dmenu = super.dmenu // { outPath = "@dmenu@"; };

        i3 = super.i3 // { outPath = "@i3@"; };

        i3status = super.i3status // { outPath = "@i3status@"; };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${./i3-followmouse-expected.conf}
    '';
  };
}
