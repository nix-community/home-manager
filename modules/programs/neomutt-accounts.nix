{ config, lib, ... }:

with lib;

{
  options.neomutt = {
    enable = mkEnableOption "NeoMutt";

    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
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
  };

  config = mkIf config.neomutt.enable {
    neomutt.sendMailCommand = mkOptionDefault (
      if config.msmtp.enable
      then "msmtpq --read-envelope-from --read-recipients"
      else null
    );
  };
}
