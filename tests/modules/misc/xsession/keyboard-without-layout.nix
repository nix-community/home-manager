{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.09";

    home.homeDirectory = "/test-home";

    home.keyboard = {
      options = [ "ctrl:nocaps" "altwin:no_win" ];
    };

    xsession = {
      enable = true;
      windowManager.command = "window manager command";
      importedVariables = [ "EXTRA_IMPORTED_VARIABLE" ];
      initExtra = "init extra commands";
      profileExtra = "profile extra commands";
    };

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/setxkbmap.service
      assertFileContent \
        home-files/.config/systemd/user/setxkbmap.service \
        ${pkgs.substituteAll {
          src = ./keyboard-without-layout-expected.service;
          inherit (pkgs.xorg) setxkbmap;
        }}
    '';
  };
}
