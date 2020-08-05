{ config, lib, ... }:

with lib;

{
  options.aerc = {
    enable = mkEnableOption "Aerc";

    source = mkOption {
      type = types.enum [ "imap" "maildir" ];
      description = "Source for reading incoming emails.";
    };

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
        Command to send a mail. If not set, aerc will be in charge of sending mails.
      '';
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      example = {
        archive = "Archive";
        folders-sort = "Archive,Sent";
      };
      description =
        "Extra lines to add to this account's specific configuration.";
    };
  };
}
