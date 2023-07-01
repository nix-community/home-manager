{ config, lib, ... }:

let
  mkNullableOption = args:
    lib.mkOption (args // {
      type = lib.types.nullOr args.type;
      default = null;
    });

  mkNullableEnableOption = name:
    lib.mkOption {
      type = with lib.types; nullOr bool;
      default = null;
      example = true;
      description = "Whether to enable ${name}.";
    };
in {
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
