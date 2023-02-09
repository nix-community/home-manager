{ config, lib, pkgs, ... }:

with lib;
with types;

let
  # attrs util that removes entries containing a null value
  compactAttrs = filterAttrs (_: val: !isNull val);

  # aliases
  himalaya = config.programs.himalaya;
  himalaya-notify = config.services.himalaya-notify;
  himalaya-watch = config.services.himalaya-watch;

  globalCfg = {
    display-name = mkOption {
      type = nullOr str;
      default = null;
      example = "Jane Doe";
      description = ''
        Name displayed when sending emails.
      '';
    };

    signature-delim = mkOption {
      type = nullOr str;
      default = null;
      example = "-- ";
      description = ''
        Delimiter used between the document and the signature.
      '';
    };

    signature = mkOption {
      type = nullOr str;
      default = null;
      example = ''
        Regards,
        Sent with Himalaya!
      '';
      description = ''
        Signature content (without delimiter).
      '';
    };

    downloads-dir = mkOption {
      type = nullOr (oneOf [ path str ]);
      default = null;
      example = "~/Downloads";
      description = ''
        Directory used to download email attachments.
      '';
    };

    folder-listing-page-size = mkOption {
      type = nullOr int;
      default = null;
      example = "50";
      description = ''
        Page size used when listing folders.
      '';
    };

    folder-aliases = mkOption {
      type = nullOr (attrsOf str);
      default = null;
      example = literalExpression ''
        {
          inbox = "INBOX";
          sent = "Sent";
          drafts = "Drafts";
          trash = "Trash";
        }
      '';
      description = ''
        Folder aliases.
      '';
    };

    email-listing-page-size = mkOption {
      type = nullOr int;
      default = null;
      example = "50";
      description = ''
        Page size used when listing emails.
      '';
    };

    email-reading-headers = mkOption {
      type = nullOr (listOf str);
      default = null;
      example = literalExpression ''
        [ "From" "To" "Subject" "Date" ]
      '';
      description = ''
        Headers shown when reading emails.
      '';
    };

    email-reading-format = mkOption {
      type = nullOr (oneOf ([ (enum [ "auto" "flowed" ]) int ]));
      default = null;
      example = "auto";
      description = ''
        Plain text format to use as defined in the <link
        xlink:href="https://www.rfc-editor.org/rfc/rfc2646">RFC
        2646</link>.
      '';
    };

    email-reading-verify-cmd = mkOption {
      type = nullOr str;
      default = null;
      example = "gpg --verify --quiet";
      description = ''
        Command used to verify the parts signature of an email.
      '';
    };

    email-reading-decrypt-cmd = mkOption {
      type = nullOr str;
      default = null;
      example = "gpg --decrypt --quiet";
      description = ''
        Command used to decrypt encrypted parts of an email.
      '';
    };

    email-writing-headers = mkOption {
      type = nullOr (listOf str);
      default = null;
      example = literalExpression ''
        [ "From" "To" "Subject" ]
      '';
      description = ''
        Headers shown by default when writing emails.
      '';
    };

    email-writing-sign-cmd = mkOption {
      type = nullOr str;
      default = null;
      example = "gpg --sign --quiet";
      description = ''
        Command used to sign parts of an email.
      '';
    };

    email-writing-encrypt-cmd = mkOption {
      type = nullOr str;
      default = null;
      example = literalExpression ''
        gpg --output - --encrypt --quiet --armor --recipient <recipient>
      '';
      description = ''
        Command used to encrypt parts of an email.
      '';
    };

    email-hooks = mkOption {
      type = nullOr (submodule {
        options = {
          pre-send = mkOption {
            type = nullOr str;
            default = null;
            example = "bash compile-markdown.sh";
            description = ''
              Command called just before sending an email.
            '';
          };
        };
      });
      default = null;
      example = literalExpression ''
        {
          pre-send = "bash compile-markdown.sh";
        }
      '';
      description = ''
        Email processing lifecycle hooks.
      '';
    };
  };

  accountCfg = globalCfg // {
    email = mkOption {
      type = nullOr (strMatching ".*@.*");
      default = null;
      example = "jane.doe@example.org";
      description = ''
        The email address of this account.
      '';
    };

    primary = mkOption {
      type = nullOr bool;
      default = null;
      example = "true";
      description = ''
        Whether this is the primary account. Only one account may be
        set as primary.
      '';
    };

    sync = mkOption {
      type = nullOr bool;
      default = null;
      example = "true";
      description = ''
        Enable the synchronization feature for this account.
      '';
    };

    sync-dir = mkOption {
      type = nullOr (oneOf [ path str ]);
      default = null;
      example = "~/.Mail";
      description = ''
        Customize the Maildir folder used by the synchronization.
        Default to <literal>$XDG_DATA_HOME/himalaya/<account-name></literal>.
      '';
    };

    backend = mkOption {
      # TODO: notmuch (requires compile flag for himalaya, libnotmuch)
      type = nullOr (enum [ "none" "imap" "maildir" ]);
      default = null;
      example = "imap";
      description = "Backend used for this account.";
    };

    imap-host = mkOption {
      type = nullOr str;
      default = null;
      example = "imap.example.org";
      description = ''
        Hostname of IMAP server.
      '';
    };

    imap-port = mkOption {
      type = nullOr port;
      default = null;
      example = "993";
      description = ''
        The port on which the IMAP server listens.
      '';
    };

    imap-ssl = mkOption {
      type = nullOr bool;
      default = null;
      example = "false";
      description = ''
        Should enable SSL/TLS.
      '';
    };

    imap-starttls = mkOption {
      type = nullOr bool;
      default = null;
      example = "false";
      description = ''
        Should enable STARTTLS.
      '';
    };

    imap-insecure = mkOption {
      type = nullOr bool;
      default = null;
      example = "false";
      description = ''
        Should trust any certificate.
      '';
    };

    imap-login = mkOption {
      type = nullOr str;
      default = null;
      example = "jane.doe@example.org";
      description = ''
        The account IMAP login.
      '';
    };

    imap-passwd-cmd = mkOption {
      type = nullOr (either str (listOf str));
      default = null;
      apply = p: if isString p then splitString " " p else p;
      example = "secret-tool lookup email me@example.org";
      description = ''
        A command, which when run writes the account password on
        standard output.
      '';
    };

    imap-notify-cmd = mkOption {
      type = nullOr str;
      default = null;
      example = literalExpression ''
        notify-send "📫 <sender>" "\<subject>"
      '';
      description = literalExpression ''
        Command used for real-time notifications. Available
        placeholders: <literal><id></literal>,
        <literal><sender></literal> or <literal><subject></literal>.
      '';
    };

    imap-notify-query = mkOption {
      type = nullOr str;
      default = null;
      example = "NOT SEEN";
      description = ''
        IMAP query used to fetch new emails in order to by notified by
        notify-cmd.
      '';
    };

    imap-watch-cmds = mkOption {
      type = nullOr (listOf str);
      default = null;
      example = literalExpression ''
        [ "mbsync -a" ]
      '';
      description = ''
        Commands executed when changes occur on the IMAP server.
      '';
    };

    maildir-root-dir = mkOption {
      type = nullOr (oneOf [ path str ]);
      default = null;
      example = "~/.emails";
      description = ''
        Path to maildir directory where emails for this account are
        stored.
      '';
    };

    sender = mkOption {
      type = nullOr (enum [ "none" "smtp" "sendmail" ]);
      default = null;
      example = "smtp";
      description = ''
        Sender used for this account.
      '';
    };

    smtp-host = mkOption {
      type = nullOr str;
      default = null;
      example = "smtp.example.org";
      description = ''
        Hostname of SMTP server.
      '';
    };

    smtp-port = mkOption {
      type = nullOr port;
      default = null;
      example = "993";
      description = ''
        The port on which the SMTP server listens.
      '';
    };

    smtp-ssl = mkOption {
      type = nullOr bool;
      default = null;
      example = "false";
      description = ''
        Should enable SSL/TLS.
      '';
    };

    smtp-starttls = mkOption {
      type = nullOr bool;
      default = null;
      example = "false";
      description = ''
        Should enable STARTTLS.
      '';
    };

    smtp-insecure = mkOption {
      type = nullOr bool;
      default = null;
      example = "false";
      description = ''
        Should trust any certificate.
      '';
    };

    smtp-login = mkOption {
      type = nullOr str;
      default = null;
      example = "jane.doe@example.org";
      description = ''
        The account SMTP login.
      '';
    };

    smtp-passwd-cmd = mkOption {
      type = nullOr (either str (listOf str));
      default = null;
      apply = p: if isString p then splitString " " p else p;
      example = "secret-tool lookup email me@example.org";
      description = ''
        A command, which when run writes the account password on
        standard output.
      '';
    };

    sendmail-cmd = mkOption {
      type = nullOr str;
      default = null;
      example = "msmtp";
      description = ''
        Sendmail command used to send emails.
      '';
    };
  };

  globalCfgModule = submodule { options = globalCfg; };

  accountCfgModule = submodule { options = accountCfg; };

  cfgFromAccount = _: account:
    {
      email = account.address;
      display-name = account.realName;
      default = account.primary;
      folder-aliases = {
        inbox = account.folders.inbox;
        sent = account.folders.sent;
        drafts = account.folders.drafts;
        trash = account.folders.trash;
      };
    }

    // optionalAttrs (account.signature.showSignature == "append") {
      # TODO: signature cannot be attached yet
      # https://todo.sr.ht/~soywod/himalaya/27
      signature = account.signature.text;
      signature-delim = account.signature.delimiter;
    }

    // optionalAttrs (!isNull account.imap) (compactAttrs {
      backend = "imap";
      imap-host = account.imap.host;
      imap-port = account.imap.port;
      imap-ssl = account.imap.tls.enable;
      imap-starttls = account.imap.tls.useStartTls;
      imap-login = account.userName;
      imap-passwd-cmd = builtins.concatStringsSep " " account.passwordCommand;
    })

    // optionalAttrs (isNull account.imap && !isNull account.maildir)
    (compactAttrs {
      backend = "maildir";
      maildir-root-dir = account.maildir.absPath;
    })

    // optionalAttrs (!isNull account.smtp) (compactAttrs {
      sender = "smtp";
      smtp-host = account.smtp.host;
      smtp-port = account.smtp.port;
      smtp-ssl = account.smtp.tls.enable;
      smtp-starttls = account.smtp.tls.useStartTls;
      smtp-login = account.userName;
      smtp-passwd-cmd = builtins.concatStringsSep " " account.passwordCommand;
    })

    // optionalAttrs (isNull account.smtp) { sender = "sendmail"; }

    // compactAttrs account.himalaya.settings;

  mkService = desc: {
    enable = mkEnableOption desc;

    account = mkOption {
      type = nullOr str;
      default = null;
      example = "gmail";
      description = ''
        Name of the account the notifier should be started for. If
        no account is given, the default account will be used.
      '';
    };

    keepalive = mkOption {
      type = nullOr int;
      default = null;
      example = "500";
      description = ''
        Lifetime of the IDLE session (in seconds). 
      '';
    };

    environment = mkOption {
      type = attrsOf str;
      default = { };
      example = literalExpression ''
        {
          "PASSWORD_STORE_DIR" = "~/.password-store";
        }
      '';
      description = ''
        Extra environment variables to be exported in the systemd
        service.
      '';
    };
  };

in {
  meta.maintainers = with hm.maintainers; [ soywod toastal ];

  options = {
    programs.himalaya = {
      enable = mkEnableOption "Enable the Himalaya email client.";

      package = mkOption {
        type = package;
        default = pkgs.himalaya;
        defaultText = literalExpression "pkgs.himalaya";
        description = ''
          Package providing the <command>himalaya</command> CLI email
          client.
        '';
      };

      settings = mkOption {
        type = globalCfgModule;
        default = { };
        description = ''
          Himalaya global configuration.
        '';
      };
    };

    services = {
      himalaya-notify =
        mkService "Enable the Himalaya new emails notifier service.";
      himalaya-watch = mkService "Enable the Himalaya watcher service.";
    };

    accounts.email.accounts = mkOption {
      type = attrsOf (submodule {
        options.himalaya = {
          enable = mkEnableOption "Enable Himalaya for this email account.";

          backend = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              Specifying 'accounts.email.accounts.*.himalaya.backend' is deprecated,
              set 'accounts.email.accounts.*.himalaya.settings.backend' instead.
            '';
          };

          sender = mkOption {
            type = nullOr str;
            description = ''
              Specifying 'accounts.email.accounts.*.himalaya.sender' is deprecated,
              set 'accounts.email.accounts.*.himalaya.settings.sender' instead.
            '';
          };

          settings = mkOption {
            type = accountCfgModule;
            default = { };
            description = ''
              Himalaya configuration for this email account.
            '';
          };
        };
      });
    };
  };

  config = mkIf himalaya.enable {
    home.packages = [ himalaya.package ];

    xdg.configFile."himalaya/config.toml".source = let
      tomlFormat = pkgs.formats.toml { };
      enabledAccounts = filterAttrs (_: account: account.himalaya.enable)
        config.accounts.email.accounts;
      globalCfg = compactAttrs himalaya.settings;
      accountsCfg = mapAttrs cfgFromAccount enabledAccounts;
      cfg = globalCfg // accountsCfg;
    in tomlFormat.generate "himalaya-config.toml" cfg;

    systemd.user.services = {
      himalaya-notify = mkIf himalaya-notify.enable {
        Unit = {
          Description = "Himalaya new emails notifier service";
          After = [ "network.target" ];
        };
        Install = { WantedBy = [ "default.target" ]; };
        Service = {
          ExecStart = "${himalaya.package}/bin/himalaya"
            + (lib.optionalString himalaya-notify.account
              " --account ${himalaya-notify.account}") + " notify"
            + (lib.optionalString himalaya-notify.keepalive
              " --keepalive ${himalaya-notify.keepalive}");
          ExecSearchPath = "/bin";
          Environment = mapAttrsToList (key: val: "${key}=${val}")
            himalaya-notify.environment;
          Restart = "always";
          RestartSec = 10;
        };
      };

      himalaya-watch = mkIf himalaya-watch.enable {
        Unit = {
          Description = "Himalaya watcher service";
          After = [ "network.target" ];
        };
        Install = { WantedBy = [ "default.target" ]; };
        Service = {
          ExecStart = "${himalaya.package}/bin/himalaya"
            + (lib.optionalString himalaya-watch.account
              " --account ${himalaya-watch.account}") + " watch"
            + (lib.optionalString himalaya-watch.keepalive
              " --keepalive ${himalaya-watch.keepalive}");
          ExecSearchPath = "/bin";
          Environment = mapAttrsToList (key: val: "${key}=${val}")
            himalaya-watch.environment;
          Restart = "always";
          RestartSec = 10;
        };
      };
    };

    warnings = (optional ("backend" ? himalaya && !isNull himalaya.backend)
      "Specifying 'accounts.email.accounts.*.himalaya.backend' is deprecated, set 'accounts.email.accounts.*.himalaya.settings.backend' instead")
      ++ (optional ("sender" ? himalaya && !isNull himalaya.sender)
        "Specifying 'accounts.email.accounts.*.himalaya.sender' is deprecated, set 'accounts.email.accounts.*.himalaya.settings.sender' instead.");
  };
}
