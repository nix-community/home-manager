{ config, lib, ... }:

with lib;

{
  options.neomutt = {
    enable = mkEnableOption "NeoMutt";

    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      default = if config.msmtp.enable then
        "msmtpq --read-envelope-from --read-recipients"
      else
        null;
      defaultText = literalExample ''
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

    onlyVirtualMailbox = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Don't use the mailboxes option of neomutt. Only use virtual-mailboxes.
        Has no effect if notmuch is not enabled.
      '';
    };

    virtualMailboxName = mkOption {
      type = types.str;
      default = "My INBOX";
      description = ''
        The name of virtual mailbox when using neomut and notmuch.
        Has no effect if notmuch is not enabled.
      '';
    };
  };
}
