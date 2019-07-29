{ config, lib, ... }:

with lib;

{
  options.khal = {
    type = mkOption {
      type = types.nullOr (types.enum [ "calendar" "discover"]);
      default = null;
      description = ''
        There is no description of this option.
      '';
    };

    glob = mkOption {
      type = types.str;
      default = "*";
      description = ''
        The glob expansion to be searched for events or birthdays when
        type is set to discover.
      '';
    };

    color = mkOption {
      type = types.nullOr (types.enum [
        "black" "white" "brown" "yellow" "dark gray" "dark green" "dark blue"
        "light gray" "light green" "light blue" "dark magenta" "dark cyan"
        "dark red" "light magenta" "light cyan" "light red"
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
        Priority of a calendar used for coloring.
      '';
    };
  };
}
