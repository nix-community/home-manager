{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.pizauth;
in
{
  meta.maintainers = [ lib.hm.maintainers.swarsel ];

  options.services.pizauth = {
    enable = lib.mkEnableOption ''
      Pizauth, a commandline OAuth2 authentication daemon
    '';

    package = lib.mkPackageOption pkgs "pizauth" { };

    extraConfig = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Additional global configuration. See pizauth.conf(5) for a available options.";
    };

    accounts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              readOnly = true;
              description = ''
                Unique identifier of the account. This is set to the
                attribute name of the account configuration.
              '';
            };

            authUri = mkOption {
              type = types.str;
              description = ''
                The OAuth2 server's authentication URI.
              '';
            };

            tokenUri = mkOption {
              type = types.str;
              description = ''
                The OAuth2 server's token URI.
              '';
            };

            clientId = mkOption {
              type = types.str;
              description = ''
                The OAuth2 client ID.
              '';
            };

            clientSecret = mkOption {
              type = types.str;
              description = ''
                The OAuth2 client secret.
              '';
            };

            scopes = mkOption {
              type = types.nullOr (types.listOf types.str);
              description = ''
                The scopes which the OAuth2 token will give access to. Optional.
                Note that Office365 requires the non-standard "offline_access" scope to be specified in order for pizauth to be able to operate successfully.
              '';
              default = [ ];
              example = [
                "https://outlook.office365.com/IMAP.AccessAsUser.All"
                "https://outlook.office365.com/SMTP.Send"
                "offline_access"
              ];
            };

            loginHint = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                An optional login hint for the account provider.
              '';
            };

            extraConfig = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Additional configuration that will be added to the account configuration. See pizauth.conf(5) for available options.
              '';
            };
          };
        }
      );
      default = { };
      description = "Pizauth accounts that should be configured";
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [ (lib.hm.assertions.assertPlatform "services.pizauth" pkgs lib.platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."pizauth.conf".source =
      let
        indent = "  ";

        renderScopes =
          scopes:
          let
            quoted = map (s: "\"${s}\"") scopes;
            joined = lib.concatStringsSep ",\n${indent}${indent}" quoted;
          in
          "[\n${indent}${indent}${joined}\n${indent}]";

        renderAccount =
          name: acc:
          ''
            account "${name}" {
            ${indent}auth_uri = "${acc.authUri}";
            ${indent}token_uri = "${acc.tokenUri}";
            ${indent}client_id = "${acc.clientId}";
            ${indent}client_secret = "${acc.clientSecret}";
          ''
          + lib.optionalString (acc.scopes != [ ] && acc.scopes != null) ''
            ${indent}scopes = ${renderScopes acc.scopes};
          ''
          + lib.optionalString (acc.loginHint != "" && acc.loginHint != null) ''
            ${indent}login_hint = "${acc.loginHint}";
          ''
          + lib.optionalString (acc.extraConfig != "" && acc.extraConfig != null) (
            let
              indentedExtraConfig = lib.concatMapStringsSep "\n" (
                line: if line == "" then "" else "${indent}${line}"
              ) (lib.splitString "\n" acc.extraConfig);
            in
            indentedExtraConfig
          )
          + ''
            }
          '';

        renderedAccounts = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: acc: renderAccount name acc) cfg.accounts
        );

      in
      pkgs.writeTextFile {
        name = "pizauth.conf";
        text =
          lib.optionalString (cfg.extraConfig != null && cfg.extraConfig != "") "${cfg.extraConfig}\n"
          + renderedAccounts;
      };

    systemd.user.services.pizauth = {
      Unit = {
        Description = "Pizauth OAuth2 token manager";
        After = [ "network.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} server -vvvv -d";
        ExecReload = "${lib.getExe cfg.package} reload";
        ExecStop = "${lib.getExe cfg.package} shutdown";
        Restart = "on-failure";

        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateUsers = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
