{ pkgs, ... }:
let
  nestedStorePath = pkgs.runCommandLocal "nested-store-path" { } ''
    mkdir -p "$out"
    ln -s ${./lua-file-from-path.lua} "$out/lua-file-in-store.lua"
  '';
in

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;

    systemd.enable = false;

    extraLuaFiles = {
      "00-vars" = ''
        local M = {}
        M.mainMod = "SUPER"
        return M
      '';

      "ui.bindings" = {
        content = ''
          local vars = require("00-vars")
          hl.bind(vars.mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
        '';
      };

      "lib.helpers" = {
        content = ''
          local M = {}
          M.terminal = "kitty"
          return M
        '';
        autoLoad = false;
      };

      "from-path.lua" = ./lua-file-from-path.lua;
      "from-nested-store-path.lua" = "${nestedStorePath}/lua-file-in-store.lua";
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.lua
    assertFileExists "$config"
    assertPathNotExists home-files/.config/hypr/hyprland.conf
    assertPathNotExists home-files/.config/hypr/.luarc.json

    assertFileContent "$config" ${./lua-files-config.lua}

    assertFileContent home-files/.config/hypr/00-vars.lua \
      ${./lua-files-00-vars.lua}

    assertFileContent home-files/.config/hypr/ui/bindings.lua \
      ${./lua-files-bindings.lua}

    assertFileContent home-files/.config/hypr/lib/helpers.lua \
      ${./lua-files-helpers.lua}

    assertFileContent home-files/.config/hypr/from-path.lua \
      ${./lua-file-from-path.lua}
    assertFileContent home-files/.config/hypr/from-nested-store-path.lua \
      ${./lua-file-from-path.lua}
  '';
}
