{ config, lib, ... }:

with lib;
{

  options.alot = {
    enable = mkEnableOption "alot";

    contactCompletionCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Command to run to send a message.
        See <link xlink:href="https://alot.readthedocs.io/en/latest/configuration/contacts_completion.html" /> for more advice.
        '';
    };

    sendMailCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Command to send a mail.
      '';
    };
  };
}
