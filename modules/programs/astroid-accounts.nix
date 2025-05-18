{ config, lib, ... }:
{
  options.astroid = {
    enable = lib.mkEnableOption "Astroid";

    sendMailCommand = lib.mkOption {
      type = lib.types.str;
      description = ''
        Command to send a mail. If msmtp is enabled for the account,
        then this is set to
        {command}`msmtpq --read-envelope-from --read-recipients`.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        select_query = "";
      };
      description = ''
        Extra settings to add to this astroid account configuration.
      '';
    };
  };

  config = lib.mkIf config.notmuch.enable {
    astroid.sendMailCommand = lib.mkIf config.msmtp.enable (
      lib.mkOptionDefault "msmtpq --read-envelope-from --read-recipients"
    );
  };
}
