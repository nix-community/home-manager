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
  };
}
