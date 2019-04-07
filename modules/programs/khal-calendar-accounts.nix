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
  };
}
