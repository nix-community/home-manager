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
      local sbar = require("sbarlua")
      sbar.bar:set({ height = 30 })
    '';
  };

  test.asserts.assertions.expected = [
    "When configType is set to \"lua\", programs.sketchybar.luaPackage must be specified or inferable from programs.sketchybar.sbarLuaPackage.passthru.luaModule"
  ];
}
