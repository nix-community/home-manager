{ config, lib, ... }:

with lib;

{
  options.khal = {
    enable = lib.mkEnableOption "khal access";

    readOnly = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Keep khal from making any changes to this account.
      '';
    };

    color = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Color in which events in this calendar are displayed.
        For instance 'light green' or an RGB color '#ff0000'
      '';
      example = "light green";
    };

    priority = mkOption {
      type = types.int;
      default = 10;
      description = ''
        Priority of a calendar used for coloring (calendar with highest priority is preferred).
      '';
    };

    addresses = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Email addresses to be associated with this account. Used to check the
        participation status ("PARTSTAT"), refer to khal documentation.
      '';
    };
  };
}
