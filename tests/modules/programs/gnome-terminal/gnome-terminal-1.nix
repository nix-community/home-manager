{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.gnome-terminal = {
      enable = true;
      profile = {
        "e0b782ed-6aca-44eb-8c75-62b3706b6220" = {
          allowBold = true;
          audibleBell = true;
          backspaceBinding = "ascii-delete";
          boldIsBright = true;
          colors = {
            backgroundColor = "#2E3436";
            foregroundColor = "#D3D7C1";
            palette = [
              "#000000"
              "#AA0000"
              "#00AA00"
              "#AA5500"
              "#0000AA"
              "#AA00AA"
              "#00AAAA"
              "#AAAAAA"
              "#555555"
              "#FF5555"
              "#55FF55"
              "#FFFF55"
              "#5555FF"
              "#FF55FF"
              "#55FFFF"
              "#FFFFFF"
            ];
          };
          cursorBlinkMode = "off";
          cursorShape = "underline";
          default = true;
          deleteBinding = "delete-sequence";
          scrollbackLines = 1000000;
          scrollOnOutput = false;
          showScrollbar = false;
          transparencyPercent = 5;
          visibleName = "kamadorueda";
        };
      };
      showMenubar = false;
    };

    nixpkgs.overlays = [
      (self: super: {
        gnome.gnome-terminal = config.lib.test.mkStubPackage { };
      })
    ];

    test.stubs.dconf = { };

    nmt.script = ''
      dconfIni=$(grep -oPm 1 '/nix/store/[a-z0-9]*?-hm-dconf.ini' $TESTED/activate)
      assertFileContent $dconfIni ${./gnome-terminal-1.conf}
    '';
  };
}
