{ config, lib, ... }:

with lib;

{
  options.khal = {
    collections = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        VCARD collections to be searched for contact birthdays.
      '';
    };
  };
}
