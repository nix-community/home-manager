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
      type = types.nullOr (types.enum [
        "black"
        "white"
        "brown"
        "yellow"
        "dark gray"
        "dark green"
        "dark blue"
        "light gray"
        "light green"
        "light blue"
        "dark magenta"
        "dark cyan"
        "dark red"
        "light magenta"
        "light cyan"
        "light red"
      ]);
      default = null;
      description = ''
        Color in which events in this calendar are displayed.
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
  };
}
