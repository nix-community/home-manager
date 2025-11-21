{ lib, ... }:

let
  mkNullableOption =
    args:
    lib.mkOption (
      args
      // {
        type = lib.types.nullOr args.type;
        default = null;
      }
    );
in
{
  freeformType = with lib.types; attrsOf (attrsOf anything);

  options = {
    "com.apple.controlcenter".BatteryShowPercentage = mkNullableOption {
      type = lib.types.bool;
      example = true;
      description = ''
        Whether to show battery percentage in the menu bar.
      '';
    };
  };
}
