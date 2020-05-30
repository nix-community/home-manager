{ config, lib, ... }:

with lib;

{
  options.neomutt = {
    enable = mkEnableOption "NeoMutt";

    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      default = config.sendMailCommand;
      example = "msmtpq --read-envelope-from --read-recipients";
      description = ''
        Override command to send a mail. Defaults to this account's
        sendMailCommand.
        If not set or null, neomutt will be in charge of sending mails.
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
}
