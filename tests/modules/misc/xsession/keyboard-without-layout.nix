{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.09";

    home.keyboard = { options = [ "ctrl:nocaps" "altwin:no_win" ]; };

    xsession = {
      enable = true;
      windowManager.command = "window manager command";
      importedVariables = [ "EXTRA_IMPORTED_VARIABLE" ];
      initExtra = "init extra commands";
      profileExtra = "profile extra commands";
    };

    nixpkgs.overlays = [
      (self: super: {
        xorg = super.xorg // {
          setxkbmap = super.xorg.setxkbmap // { outPath = "@setxkbmap@"; };
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/setxkbmap.service
      assertFileContent \
        home-files/.config/systemd/user/setxkbmap.service \
        ${./keyboard-without-layout-expected.service}
    '';
  };
}
