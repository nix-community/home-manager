{ config, lib, ... }:

with lib;

{
  options.khal = {
    type = mkOption {
      type = types.enum [ "calendar" "discover" ];
      default = "calendar";
      description = ''
        Either a single calendar (calendar which is the default) or a directory with multiple calendars (discover).
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
  };
}
