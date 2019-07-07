{ config, lib, ... }:

with lib;

{
  options.khal = {
    enable = lib.mkEnableOption "khal access";

    readOnly = mkOption {
      type = types.bool;
      description = ''
        Keep khal from making any changes to this account.
      '';
      default = false;
    };

    glob = mkOption {
      type = types.str;
      default = "*";
      description = ''
        The glob expansion to be searched for events or birthdays when type
        is set to discover.
      '';
    };
  };
}
