{ config, lib, ... }:

with lib;

let
  extraMailboxOptions = {
    options = {
      mailbox = mkOption {
        type = types.str;
        example = "Sent";
        description = lib.mdDoc "Name of mailbox folder to be included";
      };

      name = mkOption {
        type = types.nullOr types.str;
        example = "Junk";
        default = null;
        description = lib.mdDoc "Name to display";
      };
    };
  };

in {
  options.notmuch.neomutt = {
    enable = mkEnableOption (lib.mdDoc "Notmuch support in NeoMutt") // {
      default = true;
    };

    virtualMailboxes = mkOption {
      type = types.listOf (types.submodule ./notmuch-virtual-mailbox.nix);
      example = [{
        name = "My INBOX";
        query = "tag:inbox";
      }];
      default = [{
        name = "My INBOX";
        query = "tag:inbox";
      }];
      description = lib.mdDoc "List of virtual mailboxes using Notmuch queries";
    };
  };

  options.neomutt = {
    enable = mkEnableOption (lib.mdDoc "NeoMutt");

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
      description = lib.mdDoc ''
        Command to send a mail. If not set, neomutt will be in charge of sending mails.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "color status cyan default";
      description = lib.mdDoc ''
        Extra lines to add to the folder hook for this account.
      '';
    };

    mailboxName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "==== <mailbox-name> ===";
      description = lib.mdDoc "Use a different name as mailbox name";
    };

    extraMailboxes = mkOption {
      type = with types; listOf (either str (submodule extraMailboxOptions));
      default = [ ];
      description = lib.mdDoc "List of extra mailboxes";
    };
  };
}
