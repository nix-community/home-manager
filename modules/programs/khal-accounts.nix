{ config, lib, ... }:

with lib;

{
  options.khal = {
    enable = lib.mkEnableOption (lib.mdDoc "khal access");

    readOnly = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Keep khal from making any changes to this account.
      '';
    };
  };
}
