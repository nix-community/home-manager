{ config, ... }:

{
  time = "2026-05-14T00:00:00+00:00";
  condition = config.wayland.windowManager.hyprland.enable;
  message = ''
    A new option `wayland.windowManager.hyprland.extraLuaFiles` is available for
    managing additional Lua files under `$XDG_CONFIG_HOME/hypr` when using
    `wayland.windowManager.hyprland.configType = "lua"`.

    Files can be provided as paths or strings. Attribute names are treated as
    Lua module names, so `lib.helpers` writes `lib/helpers.lua`, and can be
    automatically loaded from the generated `hyprland.lua` with `require(...)`.
  '';
}
