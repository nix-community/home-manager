{ config, lib, pkgs, ... }:
let
  cfg = config.programs.himalaya;

  enabledAccounts =
    lib.filterAttrs (_: a: a.himalaya.enable) (config.accounts.email.accounts);

  tomlFormat = pkgs.formats.toml { };

  himalayaConfig = let
    toHimalayaConfig = account:
      {
        email = account.address;
        display-name = account.realName;
        default = account.primary;

        mailboxes = {
          inbox = account.folders.inbox;
          sent = account.folders.sent;
          draft = account.folders.drafts;
          # NOTE: himalaya does not support configuring the name of the trash folder
        };
      } // (lib.optionalAttrs (account.signature.showSignature == "append") {
        # FIXME: signature cannot be attached
        signature = account.signature.text;
        signature-delim = account.signature.delimiter;
      }) // (if account.himalaya.backend == null then {
        backend = "none";
      } else if account.himalaya.backend == "imap" then {
        # FIXME: does not support disabling TLS altogether
        # NOTE: does not accept sequence of strings for password commands
        backend = account.himalaya.backend;
        imap-login = account.userName;
        imap-passwd-cmd = lib.escapeShellArgs account.passwordCommand;
        imap-host = account.imap.host;
        imap-port = account.imap.port;
        imap-starttls = account.imap.tls.useStartTls;
      } else if account.himalaya.backend == "maildir" then {
        backend = account.himalaya.backend;
        maildir-root-dir = account.maildirBasePath;
      } else
        throw "Unsupported backend: ${account.himalaya.backend}")
      // (if account.himalaya.sender == null then {
        sender = "none";
      } else if account.himalaya.sender == "smtp" then {
        sender = account.himalaya.sender;
        smtp-login = account.userName;
        smtp-passwd-cmd = lib.escapeShellArgs account.passwordCommand;
        smtp-host = account.smtp.host;
        smtp-port = account.smtp.port;
        smtp-starttls = account.smtp.tls.useStartTls;
      } else if account.himalaya.sender == "sendmail" then {
        sender = account.himalaya.sender;
      } else
        throw "Unsupported sender: ${account.himalaya.sender}")
      // account.himalaya.settings;
  in {
    # NOTE: will not start without this configured, but each account overrides it
    display-name = "";
  } // cfg.settings // (lib.mapAttrs (_: toHimalayaConfig) enabledAccounts);
in {
  meta.maintainers = with lib.hm.maintainers; [ toastal ];

  options = with lib; {
    programs.himalaya = {
      enable = mkEnableOption "himalaya mail client";

      package = mkOption {
        type = types.package;
        default = pkgs.himalaya;
        defaultText = literalExpression "pkgs.himalaya";
        description = ''
          Package providing the <command>himalaya</command> mail client.
        '';
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
            email-listing-page-size = 50;
            watch-cmds = [ "mbsync -a" ]
          }
        '';
        description = ''
          Global <command>himalaya</command> configuration values.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      type = with types;
        attrsOf (submodule {
          options.himalaya = {
            enable = mkEnableOption ''
              the himalaya mail client for this account
            '';

            backend = mkOption {
              # TODO: “notmuch” (requires compile flag for himalaya, libnotmuch)
              type = types.nullOr (types.enum [ "imap" "maildir" ]);
              description = ''
                The method for which <command>himalaya</command> will fetch, store,
                etc. mail.
              '';
            };

            sender = mkOption {
              type = types.nullOr (types.enum [ "smtp" "sendmail" ]);
              description = ''
                The method for which <command>himalaya</command> will send mail.
              '';
            };

            settings = mkOption {
              type = tomlFormat.type;
              default = { };
              example = lib.literalExpression ''
                {
                  default-page-size = 50;
                }
              '';
              description = ''
                Extra settings to add to this <command>himalaya</command>
                account configuration.
              '';
            };
          };
        });
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."himalaya/config.toml".source =
      tomlFormat.generate "himalaya-config.toml" himalayaConfig;
  };
}
