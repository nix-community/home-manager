{ config, lib, ... }:

with lib;

{
  options.khal = {
    type = mkOption {
      type = types.nullOr (types.enum [ "calendar" "discover"]);
      description = ''
      '';
    };
  };
}
