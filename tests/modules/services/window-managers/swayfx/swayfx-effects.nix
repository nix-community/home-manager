{ config, pkgs, ... }:

{
  wayland.windowManager.swayfx = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@swayfx@"; };
    checkConfig = false;
    config = {
      menu = "${pkgs.dmenu}/bin/dmenu_run";
      
      # Test SwayFX-specific options
      blur = {
        enable = true;
        xray = true;
        passes = 3;
        radius = 8;
        noise = 0.1;
        brightness = 1.2;
        contrast = 0.9;
        saturation = 1.1;
      };
      
      cornerRadius = 10;
      
      shadows = {
        enable = true;
        onCsd = true;
        blurRadius = 25;
        color = "#00000080";
        offset = {
          x = 5;
          y = 5;
        };
        inactiveColor = "#00000040";
      };
      
      layerEffects = {
        "waybar" = {
          blur = {
            enable = true;
            xray = false;
            ignoreTransparent = true;
          };
          shadows = true;
          cornerRadius = 15;
        };
        "gtk-layer-shell" = {
          blur.enable = true;
          cornerRadius = 8;
        };
      };
      
      dimInactive = {
        default = 0.3;
        colors = {
          unfocused = "#333333FF";
          urgent = "#FF3333FF";
        };
      };
      
      titlebarSeparator = false;
      scratchpadMinimize = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./swayfx-effects.conf}

    assertFileExists home-files/.config/systemd/user/swayfx-session.target
  '';
}