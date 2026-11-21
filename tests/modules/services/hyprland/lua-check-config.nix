{
  config,
  lib,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = realPkgs.hyprland;
    checkConfig = true;
    portalPackage = null;
    settings.config.decoration.rounding = 4;

    extraLuaFiles."nested/example" = {
      content = "hl.config({ decoration = { rounding = 5 } })";
      autoLoad = true;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/hypr/hyprland.lua"
    assertFileExists "home-files/.config/hypr/nested/example.lua"
  '';
}
