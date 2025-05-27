{ config, ... }:
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

    # Test case for lua configuration without sbarLuaPackage
    configType = "lua";
    sbarLuaPackage = null;

    config = ''
      -- Basic lua config
      local sbar = require("sbarlua")
      sbar.bar:set({ height = 30 })
    '';
  };

  test.asserts.assertions.expected = [
    "When configType is set to \"lua\", service.sbarLuaPackage must be specified"
  ];
}
