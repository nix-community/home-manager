{ lib, ... }:
{
  options.khal = {
    collections = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
      description = ''
        VCARD collections to be searched for contact birthdays.
      '';
    };
  };
}
