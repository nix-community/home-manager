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
  };

  nmt.script = ''
    assertFileExists "home-files/.config/hypr/hyprland.lua"
  '';
}
