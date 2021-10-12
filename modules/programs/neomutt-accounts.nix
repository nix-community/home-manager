{ config, lib, ... }:

with lib;

let
  extraMailboxOptions = {
    options = {
      mailbox = mkOption {
        type = types.str;
        example = "Sent";
        description = "Name of mailbox folder to be included";
      };

      name = mkOption {
        type = types.nullOr types.str;
        example = "Junk";
        default = null;
        description = "Name to display";
      };
    };
  };

in {
  options.neomutt = {
    enable = mkEnableOption "NeoMutt";

    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      default = if config.msmtp.enable then
        "msmtpq --read-envelope-from --read-recipients"
      else
        null;
      defaultText = literalExpression ''
        if config.msmtp.enable then
          "msmtpq --read-envelope-from --read-recipients"
        else
          null
      '';
      example = "msmtpq --read-envelope-from --read-recipients";
      description = ''
        Command to send a mail. If not set, neomutt will be in charge of sending mails.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "color status cyan default";
      description = ''
        Extra lines to add to the folder hook for this account.
      '';
    };

    mailboxName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "==== <mailbox-name> ===";
      description = "Use a different name as mailbox name";
    };

    extraMailboxes = mkOption {
      type = with types; listOf (either str (submodule extraMailboxOptions));
      default = [ ];
      description = "List of extra mailboxes";
    };
  };
}
