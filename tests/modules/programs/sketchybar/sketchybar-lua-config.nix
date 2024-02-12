{ config, pkgs, ... }:

let
  pkgsSbarlua = pkgs.writeTextFile {
    name = "sbarlua";
    destination = "/bin/sbarlua";
    executable = true;
    text = ''
      #!/bin/sh
      echo "SbarLua mock"
    '';
  };
in
{
  programs.sketchybar = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    configType = "lua";
    sbarLuaPackage = pkgsSbarlua;

    variables = {
      PADDING = 3;
      FONT = "SF Pro";
      COLOR = "0xff0000ff";
      # Test more complex values
      ITEMS = [
        "calendar"
        "cpu"
        "memory"
      ];
      SETTINGS = {
        refresh_freq = 1;
        enable_logging = true;
      };
    };

    config = {
      bar = {
        height = 30;
        position = "top";
        padding_left = 10;
        padding_right = 10;
        blur_radius = 20;
        corner_radius = 9;
      };

      defaults = {
        "icon.font" = "$FONT";
        "icon.color" = "$COLOR";
        "background.height" = 24;
        "label.padding" = "$PADDING";
        "popup.background.border_width" = 2;
        "popup.background.corner_radius" = 9;
      };
    };

    extraConfig = ''
      -- This is a test Lua configuration
      sbar:add("item", "cpu", {
        position = "right",
        update_freq = 1,
        script = "./scripts/cpu.lua"
      })

      -- Subscribe to events
      sbar:subscribe("cpu", "system_woke")
    '';
  };

  # Validate the generated Lua configuration file
  nmt.script = ''
    assertFileContent \
      home-files/.config/sketchybar/sketchybarrc \
      ${./sketchybarrc.lua}
  '';
}
