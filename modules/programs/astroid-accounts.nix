{ config, lib, ... }:

with lib;

{
  options.astroid = {
    enable = mkEnableOption (lib.mdDoc "Astroid");

    sendMailCommand = mkOption {
      type = types.str;
      description = lib.mdDoc ''
        Command to send a mail. If msmtp is enabled for the account,
        then this is set to
        {command}`msmtpq --read-envelope-from --read-recipients`.
      '';
    };

    extraConfig = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      example = { select_query = ""; };
      description = lib.mdDoc ''
        Extra settings to add to this astroid account configuration.
      '';
    };
  };

  config = mkIf config.notmuch.enable {
    astroid.sendMailCommand = mkIf config.msmtp.enable
      (mkOptionDefault "msmtpq --read-envelope-from --read-recipients");
  };
}
