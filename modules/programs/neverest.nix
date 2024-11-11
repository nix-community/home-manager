{ config, lib, pkgs, ... }:

let
  inherit (config.programs) neverest;

  toml = pkgs.formats.toml { };

  backendType = lib.types.enum [ "imap" "maildir" "notmuch" ];

  mkEncryptionConfig = tls:
    if tls.useStartTls then
      "start-tls"
    else if tls.enable then
      "tls"
    else
      "none";

  mkBackendConfig = account:
    let
      hmAccount = config.accounts.email.accounts.${account.name};
      notmuchEnabled = account.backend == "notmuch"
        && hmAccount.notmuch.enable or false;
      imapEnabled = account.backend == "imap" && !isNull hmAccount.imap
        && !notmuchEnabled;
      maildirEnabled = account.backend == "maildir" && !isNull hmAccount.maildir
        && !imapEnabled && !notmuchEnabled;

    in lib.optionalAttrs (imapEnabled) {
      type = "imap";
      host = hmAccount.imap.host;
      port = hmAccount.imap.port;
      encryption = mkEncryptionConfig hmAccount.imap.tls;
      login = hmAccount.userName;
      passwd.cmd = builtins.concatStringsSep " " hmAccount.passwordCommand;

    } // lib.optionalAttrs (maildirEnabled) {
      type = "maildir";
      root-dir = hmAccount.maildir.absPath;

    } // lib.optionalAttrs (notmuchEnabled) {
      type = "notmuch";
      database-path = config.accounts.email.maildirBasePath;
    };

  mkAccountConfig = accountName: account:
    let
      leftBackend = { backend = mkBackendConfig account.left; };
      rightBackend = { backend = mkBackendConfig account.right; };

    in lib.recursiveUpdate account.settings {
      left = lib.recursiveUpdate leftBackend account.left.settings;
      right = lib.recursiveUpdate rightBackend account.right.settings;
    };

in {
  meta.maintainers = with lib.hm.maintainers; [ soywod ];

  options = {
    programs.neverest = {
      enable = lib.mkEnableOption "the email synchronizer Neverest CLI";

      package = lib.mkPackageOption pkgs "neverest" { };

      accounts = lib.mkOption {
        description = ''
          Accounts configuration.
        '';
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            left = lib.mkOption {
              description = ''
                Account configuration of the left backend.
                See <https://pimalaya.org/neverest/cli/latest/configuration/#account-configuration> for supported values.
              '';
              type = lib.types.submodule {
                options = {
                  backend = lib.mkOption {
                    type = backendType;
                    description = ''
                      The type of the left backend.
                    '';
                  };

                  name = lib.mkOption {
                    type = lib.types.enum
                      (builtins.attrNames config.accounts.email.accounts);
                    description = ''
                      The name of the Home Manager email account to use
                      as the left side of the current Neverest account.
                    '';
                  };

                  settings = lib.mkOption {
                    type = lib.types.submodule { freeformType = toml.type; };
                    default = { };
                    description = ''
                      Additional account configuration of the left backend.
                      See <https://pimalaya.org/neverest/cli/latest/configuration/#account-configuration> for supported values.
                    '';
                  };
                };
              };
            };

            right = lib.mkOption {
              description = ''
                Account configuration of the right backend.
                See <https://pimalaya.org/neverest/cli/latest/configuration/#account-configuration> for supported values.
              '';
              type = lib.types.submodule {
                options = {
                  backend = lib.mkOption {
                    type = backendType;
                    description = ''
                      The type of the right backend.
                    '';
                  };

                  name = lib.mkOption {
                    type = lib.types.enum
                      (builtins.attrNames config.accounts.email.accounts);
                    description = ''
                      The name of the Home Manager email account to use
                      as the right side of the current Neverest account.
                    '';
                  };

                  settings = lib.mkOption {
                    type = lib.types.submodule { freeformType = toml.type; };
                    default = { };
                    description = ''
                      Additional account configuration of the right backend.
                      See <https://pimalaya.org/neverest/cli/latest/configuration/#account-configuration> for supported values.
                    '';
                  };
                };
              };

            };

            settings = lib.mkOption {
              type = lib.types.submodule { freeformType = toml.type; };
              default = { };
              description = ''
                Additional account configuration.
                See <https://pimalaya.org/neverest/cli/latest/configuration/#account-configuration> for supported values.
              '';
            };
          };
        });
      };
    };
  };

  config = lib.mkIf neverest.enable {
    home.packages = [ neverest.package ];

    xdg = {
      configFile."neverest/config.toml".source =
        toml.generate "neverest-config.toml" {
          accounts = lib.mapAttrs mkAccountConfig neverest.accounts;
        };
    };
  };
}
