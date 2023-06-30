{ config, lib, ... }:

with lib;

let

  extraConfigType = with types; attrsOf (either (either str int) bool);

in {
  options.offlineimap = {
    enable = mkEnableOption (lib.mdDoc "OfflineIMAP");

    extraConfig.account = mkOption {
      type = extraConfigType;
      default = { };
      example = { autorefresh = 20; };
      description = lib.mdDoc ''
        Extra configuration options to add to the account section.
      '';
    };

    extraConfig.local = mkOption {
      type = extraConfigType;
      default = { };
      example = { sync_deletes = true; };
      description = lib.mdDoc ''
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
      description = lib.mdDoc ''
        Extra configuration options to add to the remote account
        section.
      '';
    };

    postSyncHookCommand = mkOption {
      type = types.lines;
      default = "";
      description = lib.mdDoc "Command to run after fetching new mails.";
    };
  };
}
