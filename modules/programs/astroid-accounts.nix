{ config, lib, ... }:

with lib;

{
  options.astroid = {
    enable = mkEnableOption "Astroid";

    sendMailCommand = mkOption {
      type = types.str;
      default = config.sendMailCommand;
      description = ''
        Override command to send a mail. Defaults to this account's
        sendMailCommand.
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      example = { select_query = ""; };
      description = ''
        Extra settings to add to this astroid account configuration.
      '';
    };
  };
}
