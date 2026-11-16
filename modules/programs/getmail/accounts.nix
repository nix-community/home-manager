{ iniFormat }:
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  imports =
    lib.hm.deprecations.mkSettingsRenamedOptionModules [ "getmail" ] [ "getmail" "settings" ] { }
      [
        {
          old = "delete";
          new = [
            "options"
            "delete"
          ];
        }
        {
          old = "readAll";
          new = [
            "options"
            "read_all"
          ];
        }
      ];

  options.getmail = {
    enable = lib.mkEnableOption "the getmail mail retriever for this account";

    destinationCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${pkgs.maildrop}/bin/maildrop";
      description = ''
        Specify a command delivering the incoming mail to your maildir.
      '';
    };

    mailboxes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "INBOX"
        "INBOX.spam"
      ];
      description = ''
        Mailboxes to retrieve. An empty list omits the setting, for retrievers
        such as POP3 that do not use mailboxes. To download all IMAP mail,
        use the `ALL` mailbox.
      '';
    };

    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        retriever.password_command = "('pass', 'show', 'mail/example')";
        destination.arguments = "('--message-from-stdin',)";
        "filter-1" = {
          type = "Filter_external";
          path = "/path/to/filter";
        };
      };
      description = ''
        Native INI settings for this getmail account. Tuple values must be
        provided as raw getmail tuple syntax strings. Account connection and
        delivery options supply defaults that can be overridden per key.

        See <https://getmail6.org/configuration.html> for available settings.
      '';
    };
  };

  config = lib.mkMerge [
    {
      getmail.settings.options = {
        delete = lib.mkOptionDefault false;
        read_all = lib.mkOptionDefault true;
      };
    }
    (lib.mkIf config.getmail.enable {
      getmail.settings = {
        retriever = {
          type = lib.mkDefault (
            if config.imap.tls.enable then "SimpleIMAPSSLRetriever" else "SimpleIMAPRetriever"
          );
          server = lib.mkDefault config.imap.host;
          port = lib.mkIf (config.imap != null && config.imap.port != null) (lib.mkDefault config.imap.port);
          username = lib.mkDefault config.userName;
          password_command = lib.mkIf (config.passwordCommand != null) (
            lib.mkDefault "(${lib.concatMapStringsSep ", " (x: "'${x}'") config.passwordCommand})"
          );
          mailboxes = lib.mkIf (config.getmail.mailboxes != [ ]) (
            lib.mkDefault "( ${lib.concatMapStrings (x: "'${x}', ") config.getmail.mailboxes} )"
          );
        };
        destination = {
          type = lib.mkDefault (
            if config.getmail.destinationCommand != null then "MDA_external" else "Maildir"
          );
          path = lib.mkDefault (
            if config.getmail.destinationCommand != null then
              config.getmail.destinationCommand
            else
              "${config.maildir.absPath}/"
          );
        };
      };
    })
  ];
}
