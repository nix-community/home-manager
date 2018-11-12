{ config, lib, ... }:

with lib;

{
  options.alot = {
    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      description = ''
        Command to send a mail. If msmtp is enabled for the account,
        then this is set to
        <command>msmtpq --read-envelope-from --read-recipients</command>.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra settings to add to this Alot account configuration.
      '';
    };
  };

  config = mkIf config.notmuch.enable {
    alot.sendMailCommand = mkOptionDefault (
      if config.msmtp.enable
      then "msmtpq --read-envelope-from --read-recipients"
      else null
    );
  };
}
