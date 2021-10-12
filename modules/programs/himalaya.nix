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
        name = account.realName;
        default = account.primary;

        # FIXME: does not support disabling TLS altogether
        # NOTE: does not accept sequence of strings for password commands
        imap-login = account.userName;
        imap-passwd-cmd = lib.escapeShellArgs account.passwordCommand;
        imap-host = account.imap.host;
        imap-port = account.imap.port;
        imap-starttls = account.imap.tls.useStartTls;

        smtp-login = account.userName;
        smtp-passwd-cmd = lib.escapeShellArgs account.passwordCommand;
        smtp-host = account.smtp.host;
        smtp-port = account.smtp.port;
        smtp-starttls = account.imap.tls.useStartTls;
      } // (lib.optionalAttrs (account.signature.showSignature == "append") {
        # FIXME: signature cannot be attached
        signature = account.signature.text;
      }) // account.himalaya.settings;
  in {
    # NOTE: will not start without this configured, but each account overrides it
    name = "";
  } // cfg.settings // (lib.mapAttrs (_: toHimalayaConfig) enabledAccounts);
in {
  meta.maintainers = with lib.hm.maintainers; [ ambroisie ];

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
            default-page-size = 50;
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
