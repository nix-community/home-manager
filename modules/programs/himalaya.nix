{ config, lib, pkgs, ... }:

let
  # aliases
  inherit (config.programs) himalaya;
  tomlFormat = pkgs.formats.toml { };

  # attrs util that removes entries containing a null value
  compactAttrs = lib.filterAttrs (_: val: !isNull val);

  # Needed for notmuch config, because the DB is here, and not in each account's dir
  maildirBasePath = config.accounts.email.maildirBasePath;

  # make a himalaya config from a home-manager email account config
  mkAccountConfig = _: account:
    let
      # Use notmuch if it's enabled, otherwise fallback to IMAP then maildir
      # Maildir is always set, so there's no easy way to detect if it's being used
      notmuchEnabled = account.notmuch.enable;
      imapEnabled = !isNull account.imap && !notmuchEnabled;
      maildirEnabled = !isNull account.maildir && !imapEnabled
        && !notmuchEnabled;

      globalConfig = {
        email = account.address;
        display-name = account.realName;
        default = account.primary;
        folder-aliases = {
          inbox = account.folders.inbox;
          sent = account.folders.sent;
          drafts = account.folders.drafts;
          trash = account.folders.trash;
        };
      };

      signatureConfig =
        lib.optionalAttrs (account.signature.showSignature == "append") {
          # TODO: signature cannot be attached yet
          # https://todo.sr.ht/~soywod/pimalaya/27
          signature = account.signature.text;
          signature-delim = account.signature.delimiter;
        };

      imapConfig = lib.optionalAttrs imapEnabled (compactAttrs {
        backend = "imap";
        imap-host = account.imap.host;
        imap-port = account.imap.port;
        imap-ssl = account.imap.tls.enable;
        imap-starttls = account.imap.tls.useStartTls;
        imap-login = account.userName;
        imap-auth = "passwd";
        imap-passwd.cmd = builtins.concatStringsSep " " account.passwordCommand;
      });

      maildirConfig = lib.optionalAttrs maildirEnabled (compactAttrs {
        backend = "maildir";
        maildir-root-dir = account.maildir.absPath;
      });

      notmuchConfig = lib.optionalAttrs notmuchEnabled (compactAttrs {
        backend = "notmuch";
        notmuch-db-path = maildirBasePath;
      });

      smtpConfig = lib.optionalAttrs (!isNull account.smtp) (compactAttrs {
        sender = "smtp";
        smtp-host = account.smtp.host;
        smtp-port = account.smtp.port;
        smtp-ssl = account.smtp.tls.enable;
        smtp-starttls = account.smtp.tls.useStartTls;
        smtp-login = account.userName;
        smtp-auth = "passwd";
        smtp-passwd.cmd = builtins.concatStringsSep " " account.passwordCommand;
      });

      sendmailConfig =
        lib.optionalAttrs (isNull account.smtp && !isNull account.msmtp) {
          sender = "sendmail";
          sendmail-cmd = "${pkgs.msmtp}/bin/msmtp";
        };

      config = globalConfig // signatureConfig // imapConfig // maildirConfig
        // notmuchConfig // smtpConfig // sendmailConfig;

    in lib.recursiveUpdate config account.himalaya.settings;

  # make a systemd service config from a name and a description
  mkServiceConfig = name: desc:
    let
      inherit (config.services."himalaya-${name}") enable environment settings;
      optionalArg = key:
        if (key ? settings && !isNull settings."${key}") then
          [ "--${key} ${settings."${key}"}" ]
        else
          [ ];
    in {
      "himalaya-${name}" = lib.mkIf enable {
        Unit = {
          Description = desc;
          After = [ "network.target" ];
        };
        Install = { WantedBy = [ "default.target" ]; };
        Service = {
          ExecStart = lib.concatStringsSep " "
            ([ "${himalaya.package}/bin/himalaya" ] ++ optionalArg "account"
              ++ [ name ] ++ optionalArg "keepalive");
          ExecSearchPath = "/bin";
          Environment =
            lib.mapAttrsToList (key: val: "${key}=${val}") environment;
          Restart = "always";
          RestartSec = 10;
        };
      };
    };

in {
  meta.maintainers = with lib.hm.maintainers; [ soywod toastal ];

  options = {
    programs.himalaya = {
      enable = lib.mkEnableOption "the Himalaya email client";
      package = lib.mkPackageOption pkgs "himalaya" { };
      settings = lib.mkOption {
        type = lib.types.submodule { freeformType = tomlFormat.type; };
        default = { };
        description = ''
          Himalaya global configuration.
          See <https://pimalaya.org/himalaya/cli/configuration/global.html> for supported values.
        '';
      };
    };

    services = {
      himalaya-notify = {
        enable = lib.mkEnableOption "the Himalaya new emails notifier service";

        environment = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          example = lib.literalExpression ''
            {
              "PASSWORD_STORE_DIR" = "~/.password-store";
            }
          '';
          description = ''
            Extra environment variables to be exported in the service.
          '';
        };

        settings = {
          account = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            example = "gmail";
            description = ''
              Name of the account the notifier should be started for. If
              no account is given, the default one is used.
            '';
          };

          keepalive = lib.mkOption {
            type = with lib.types; nullOr int;
            default = null;
            example = "500";
            description = ''
              Notifier lifetime of the IDLE session (in seconds). 
            '';
          };
        };
      };

      himalaya-watch = {
        enable =
          lib.mkEnableOption "the Himalaya folder changes watcher service";

        environment = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          example = lib.literalExpression ''
            {
              "PASSWORD_STORE_DIR" = "~/.password-store";
            }
          '';
          description = ''
            Extra environment variables to be exported in the service.
          '';
        };

        settings = {
          account = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            example = "gmail";
            description = ''
              Name of the account the watcher should be started for. If
              no account is given, the default one is used.
            '';
          };

          keepalive = lib.mkOption {
            type = with lib.types; nullOr int;
            default = null;
            example = "500";
            description = ''
              Watcher lifetime of the IDLE session (in seconds). 
            '';
          };
        };
      };
    };

    accounts.email.accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.himalaya = {
          enable = lib.mkEnableOption "Himalaya for this email account";

          # TODO: remove me for the next release
          backend = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = ''
              Specifying {option}`accounts.email.accounts.*.himalaya.backend` is deprecated,
              set {option}`accounts.email.accounts.*.himalaya.settings.backend` instead.
            '';
          };

          # TODO: remove me for the next release
          sender = lib.mkOption {
            type = with lib.types; nullOr str;
            description = ''
              Specifying {option}`accounts.email.accounts.*.himalaya.sender` is deprecated,
              set {option}'accounts.email.accounts.*.himalaya.settings.sender' instead.
            '';
          };

          settings = lib.mkOption {
            type = lib.types.submodule { freeformType = tomlFormat.type; };
            default = { };
            description = ''
              Himalaya configuration for this email account.
              See <https://pimalaya.org/himalaya/cli/configuration/account.html> for supported values.
            '';
          };
        };
      });
    };
  };

  config = lib.mkIf himalaya.enable {
    home.packages = [ himalaya.package ];

    xdg.configFile."himalaya/config.toml".source = let
      enabledAccounts = lib.filterAttrs (_: account: account.himalaya.enable)
        config.accounts.email.accounts;
      accountsConfig = lib.mapAttrs mkAccountConfig enabledAccounts;
      globalConfig = compactAttrs himalaya.settings;
      allConfig = globalConfig // accountsConfig;
    in tomlFormat.generate "himalaya-config.toml" allConfig;

    systemd.user.services = { }
      // mkServiceConfig "notify" "Himalaya new emails notifier service"
      // mkServiceConfig "watch" "Himalaya folder changes watcher service";

    # TODO: remove me for the next release
    warnings = (lib.optional ("backend" ? himalaya && !isNull himalaya.backend)
      "Specifying 'accounts.email.accounts.*.himalaya.backend' is deprecated, set 'accounts.email.accounts.*.himalaya.settings.backend' instead")
      ++ (lib.optional ("sender" ? himalaya && !isNull himalaya.sender)
        "Specifying 'accounts.email.accounts.*.himalaya.sender' is deprecated, set 'accounts.email.accounts.*.himalaya.settings.sender' instead.");
  };
}
