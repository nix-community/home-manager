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
        Keep khal from making any changes to this calendar.
      '';
      default = false;
    };

    glob = mkOption {
      type = types.str;
      default = "*";
      description = ''
        The glob expansation to be searched for events or birthdays when type
        is set to discover.
      '';
    };
  };

  config = mkIf config.khal.enable {
  };
}
