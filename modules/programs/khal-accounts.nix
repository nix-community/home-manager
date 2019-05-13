{ config, lib, ... }:

with lib;

{
  options.khal = {
    enable = lib.mkEnableOption "khal access";

    type = mkOption {
      # todo default/assert only birthdays for contacts
      type = types.nullOr (types.enum [ "calendar" "birthdays" "discover"]);
      description = ''
      '';
      default = null;
    };

    readOnly = mkOption {
      type = types.bool;
      description = ''
      '';
      default = false;
    };
  };

  config = mkIf config.khal.enable {
  };
}
