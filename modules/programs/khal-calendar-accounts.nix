{ lib, ... }:
{
  options.khal = {
    type = lib.mkOption {
      type = lib.types.enum [
        "calendar"
        "discover"
      ];
      default = "calendar";
      description = ''
        Either a single calendar (calendar which is the default) or a directory with multiple calendars (discover).
      '';
    };

    glob = lib.mkOption {
      type = lib.types.str;
      default = "*";
      description = ''
        The glob expansion to be searched for events or birthdays when
        type is set to discover.
      '';
    };
  };
}
