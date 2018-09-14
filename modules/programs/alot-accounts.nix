{ config, lib, ... }:

with lib;

{
  options.alot = {
    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      description = ''
        Command to send a mail. If msmtp is enabled for the account,
        then this is set to
        <command>msmtpq --account=&lt;name&gt; -t</command>.
      '';
    };
  };

  config = mkIf config.notmuch.enable {
    alot.sendMailCommand = mkOptionDefault (
      if config.msmtp.enable
      then "msmtpq --account=${config.name} -t"
      else null
    );
  };
}
