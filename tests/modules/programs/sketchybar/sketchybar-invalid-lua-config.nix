{ config, ... }:
{
  programs.sketchybar = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    # Test case for lua configuration without sbarLuaPackage
    configType = "lua";
    # sbarLuaPackage intentionally not set

    variables = {
      PADDING = 3;
    };

    config.bar = {
      height = 30;
    };
  };

  test.asserts.assertions.expected = [
    "When configType is set to \"lua\", sbarLuaPackage must be specified"
  ];
}
