{ config, lib, ... }:

with lib;

let
  contactCompletionStr = let
    in
    contactCompletion:
    (if contactCompletion == "notmuch address" then {

      type = "shellcommand";
      command = "'notmuch  address --format=json --output=recipients  date:1Y..'";
      regexp = '''\[?{"name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"}[,\]]?''\''';
      shellcommand_external_filtering = "False";
    }
    else if contactCompletion == "notmuch address simple" then {
      command = "notmuch address --format=json date:1Y..";
    }
    else if contactCompletion == "abook" then {
      type = "abook";
    } else {});
in
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
      type = types.enum [ "notmuch address simple" "notmuch address" ];
      default = "notmuch address";
      apply = v:
        contactCompletionStr v;

      description = ''
       Contact completion command.
       See <link xlink:href="http://alot.readthedocs.io/en/latest/configuration/contacts_completion.html">alot's wiki</link> for
       some more explanation.
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
