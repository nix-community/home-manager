{ lib }:
let
  renderSetting = setting: {
    base_value = setting.baseValue;
    inherit (setting) inputs;
  };
in
{
  toBrushFile =
    brush:
    builtins.toJSON {
      inherit (brush) comment;
      inherit (brush) group;
      parent_brush_name = brush.parentBrushName;
      inherit (brush) version;
      settings = lib.mapAttrs (_: renderSetting) brush.settings;
    };
}
