{ config, ... }:

{
  wayland.windowManager.niri = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@niri@"; };
    config = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            file = "~/.config/keymap.xkb";
          };
          numlock = true;
        };
        touchpad = {
          tap = true;
          naturalScroll  = true;
        };
        mouse = {
          accelSpeed = 0.2;
        };
        trackpoint = {
          off = true;
          leftHanded = true;
        };
      };
      workspaces = {
        music = {};
        web = {
          openOnOutput = "DP-2";
          layout.gaps = 32;
        };
      };
      outputs = {
        "eDP-1".mode = "1920x1080@120.030";
        "HDMI-A-1".off = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/niri/config.kdl
    assertFileContent $(normalizeStorePaths home-files/.config/niri/config.kdl) \
      ${./niri-minimal.kdl}
  '';
}
