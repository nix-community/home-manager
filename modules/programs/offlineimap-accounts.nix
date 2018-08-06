{ config, lib, ... }:

with lib;

{
  options.offlineimap = {
    enable = mkEnableOption "OfflineIMAP";

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration lines added on a per-account basis.
        '';
    };

    postSyncHookCommand = mkOption {
      type = types.lines;
      default = "";
      description = "command to run after fetching new mails";
    };
  };
}

