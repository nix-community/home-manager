{ config, lib, pkgs, ... }:

{
  config = {
    wayland.windowManager.sway.swaynag = {
      enable = true;

      settings = {
        "<config>" = {
          edge = "bottom";
          font = "Dina 12";
        };

        green = {
          edge = "top";
          background = "00AA00";
          text = "FFFFFF";
          button-background = "00CC00";
          message-padding = 10;
        };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/swaynag/config \
        ${./swaynag-example-settings-expected.conf}
    '';
  };
}
