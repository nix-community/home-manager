{ config, lib, ... }:

with lib;

let

  extraConfigType = with types; attrsOf (either (either str int) bool);

in {
  options.offlineimap = {
    enable = mkEnableOption "OfflineIMAP";

    extraConfig.account = mkOption {
      type = extraConfigType;
      default = { };
      example = { autorefresh = 20; };
      description = ''
        Extra configuration options to add to the account section.
      '';
    };

    extraConfig.local = mkOption {
      type = extraConfigType;
      default = { };
      example = { sync_deletes = true; };
      description = ''
        Extra configuration options to add to the local account
        section.
      '';
    };

    extraConfig.remote = mkOption {
      type = extraConfigType;
      default = { };
      example = {
        maxconnections = 2;
        expunge = false;
      };
      description = ''
        Extra configuration options to add to the remote account
        section.
      '';
    };

    postSyncHookCommand = mkOption {
      type = types.lines;
      default = "";
      description = "Command to run after fetching new mails.";
    };
  };
}
