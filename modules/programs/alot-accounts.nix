pkgs:
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

    contactCompletion = mkOption {
      type = types.attrsOf types.str;
      default = {
        type = "shellcommand";
        command =
          "'${pkgs.notmuch}/bin/notmuch address --format=json --output=recipients  date:6M..'";
        regexp = "'\\[?{" + ''
          "name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"''
          + "}[,\\]]?'";
        shellcommand_external_filtering = "False";
      };
      example = literalExpression ''
        {
          type = "shellcommand";
          command = "abook --mutt-query";
          regexp = "'^(?P<email>[^@]+@[^\t]+)\t+(?P<name>[^\t]+)'";
          ignorecase = "True";
        }
      '';
      description = ''
        Contact completion configuration as expected per alot.
        See <link xlink:href="http://alot.readthedocs.io/en/latest/configuration/contacts_completion.html">alot's wiki</link> for
        explanation about possible values.
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
    alot.sendMailCommand = mkOptionDefault (if config.msmtp.enable then
      "msmtpq --read-envelope-from --read-recipients"
    else
      null);
  };
}
