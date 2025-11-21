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
    package = config.lib.test.mkStubPackage {
      name = "sketchybar";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/sketchybar
        chmod 755 $out/bin/sketchybar
      '';
    };

    configType = "lua";

    sbarLuaPackage = pkgsSbarlua;

    config = ''
      -- This is a test Lua configuration
      local sbar = require("sbarlua")

      -- Configure bar
      sbar.bar:set({
        height = 30,
        position = "top",
        padding_left = 10,
        padding_right = 10,
        blur_radius = 20,
        corner_radius = 9,
      })

      -- Configure defaults
      sbar.defaults:set({
        ["icon.font"] = "SF Pro",
        ["icon.color"] = "0xff0000ff",
        ["background.height"] = 24,
        ["popup.background.border_width"] = 2,
        ["popup.background.corner_radius"] = 9,
      })

      -- Add items
      sbar:add("item", "cpu", {
        position = "right",
        update_freq = 1,
        script = "./scripts/cpu.lua",
      })

      -- Subscribe to events
      sbar:subscribe("cpu", "system_woke")

      -- Update the bar
      sbar:update()'';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/sketchybar/sketchybarrc \
      ${./sketchybarrc.lua}
  '';
}
