{ lib, ... }:
let
  extraConfigType =
    with lib.types;
    attrsOf (oneOf [
      str
      int
      bool
      (listOf str)
    ]);
in
{
  options.imapgoose = {
    enable = lib.mkEnableOption "synchronization using ImapGoose";

    maxConnections = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 3;
      description = "Maximum concurrent IMAP connections for this account.";
    };

    postSyncCmd = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "notmuch new";
      description = "Command to execute after synchronization finishes.";
    };

    extraConfig = lib.mkOption {
      type = extraConfigType;
      default = { };
      example = {
        timeout = 60;
        debug = true;
      };
      description = "Extra configuration to inject into this account's block.";
    };
  };
}
