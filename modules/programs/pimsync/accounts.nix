{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.hm.types) SCFGDirectives;
in
{
  options.pimsync = {
    enable = lib.mkEnableOption "synchronization using pimsync";

    extraRemoteStorageDirectives = mkOption {
      type = SCFGDirectives;
      default = [ ];
      description = "Extra directives that should be added under this accounts remote storage directive";
    };

    extraLocalStorageDirectives = mkOption {
      type = SCFGDirectives;
      default = [ ];
      description = "Extra directives that should be added under this accounts local storage directive";
    };

    extraPairDirectives = mkOption {
      type = SCFGDirectives;
      default = [ ];
      description = "Extra directives that should be added under this accounts pair directive";
    };
  };
}
